import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  /// 生成加密密钥（房间密码左偏移2位）
  String _generateEncryptionKey(String roomPassword) {
    if (roomPassword.length < 2) {
      // 如果密码长度小于2，直接返回原密码
      return roomPassword;
    }
    // 左偏移2位：将前2个字符移到末尾
    return roomPassword.substring(2) + roomPassword.substring(0, 2);
  }

  /// 从密钥生成AES Key
  Uint8List _createAESKey(String encryptionKey) {
    // 使用SHA256哈希确保密钥长度为32字节
    final keyBytes = sha256.convert(utf8.encode(encryptionKey)).bytes;
    return Uint8List.fromList(keyBytes);
  }

  /// 生成随机IV
  Uint8List _generateRandomIV() {
    final random = Random.secure();
    final iv = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// 加密消息
  String encryptMessage(String message, String roomPassword) {
    try {
      final encryptionKey = _generateEncryptionKey(roomPassword);
      final key = _createAESKey(encryptionKey);
      final iv = _generateRandomIV();
      
      // 创建AES-CBC加密器
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(true, params);
      
      // 准备明文数据（添加PKCS7填充）
      final messageBytes = utf8.encode(message);
      final paddedMessage = _addPKCS7Padding(messageBytes, 16);
      
      // 加密
      final encrypted = Uint8List(paddedMessage.length);
      int offset = 0;
      while (offset < paddedMessage.length) {
        offset += cipher.processBlock(paddedMessage, offset, encrypted, offset);
      }
      
      // 将IV和加密数据组合，用base64编码
      final combined = Uint8List.fromList(iv + encrypted);
      return base64Encode(combined);
    } catch (e) {
      print('加密消息失败: $e');
      return message; // 加密失败时返回原消息
    }
  }

  /// 解密消息
  String decryptMessage(String encryptedMessage, String roomPassword) {
    try {
      final encryptionKey = _generateEncryptionKey(roomPassword);
      final key = _createAESKey(encryptionKey);
      
      // 解码base64
      final combined = base64Decode(encryptedMessage);
      
      // 分离IV和加密数据
      final iv = Uint8List.fromList(combined.take(16).toList());
      final encryptedBytes = Uint8List.fromList(combined.skip(16).toList());
      
      // 创建AES-CBC解密器
      final cipher = CBCBlockCipher(AESEngine());
      final params = ParametersWithIV(KeyParameter(key), iv);
      cipher.init(false, params);
      
      // 解密
      final decrypted = Uint8List(encryptedBytes.length);
      int offset = 0;
      while (offset < encryptedBytes.length) {
        offset += cipher.processBlock(encryptedBytes, offset, decrypted, offset);
      }
      
      // 移除PKCS7填充
      final unpaddedMessage = _removePKCS7Padding(decrypted);
      return utf8.decode(unpaddedMessage);
    } catch (e) {
      print('解密消息失败: $e');
      return encryptedMessage; // 解密失败时返回原消息
    }
  }

  /// 添加PKCS7填充
  Uint8List _addPKCS7Padding(List<int> data, int blockSize) {
    final padding = blockSize - (data.length % blockSize);
    final paddedData = Uint8List(data.length + padding);
    paddedData.setRange(0, data.length, data);
    for (int i = data.length; i < paddedData.length; i++) {
      paddedData[i] = padding;
    }
    return paddedData;
  }

  /// 移除PKCS7填充
  Uint8List _removePKCS7Padding(Uint8List data) {
    final padding = data.last;
    return Uint8List.fromList(data.take(data.length - padding).toList());
  }

  /// 检查消息是否已加密（简单检查是否为base64格式）
  bool isEncryptedMessage(String message) {
    try {
      base64Decode(message);
      return true;
    } catch (e) {
      return false;
    }
  }
}