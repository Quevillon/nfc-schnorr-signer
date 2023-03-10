import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tangem_nfc_reader/InfoWidget.dart';
import 'package:tangem_sdk/tangem_sdk.dart';
import 'package:tangem_nfc_reader/app_widgets.dart';
import 'package:tangem_nfc_reader/utils.dart';

void main() {

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context),
      home: Scaffold(
        appBar: AppBar(title: const Text('Tangem SDK NFC Reader')),
        body: CommandListWidget(),
      ),
    );
  }
}

class CommandListWidget extends StatefulWidget {
  @override
  _CommandListWidgetState createState() => _CommandListWidgetState();
}

class _CommandListWidgetState extends State<CommandListWidget> {
  final Utils _utils = Utils();
  final _jsonEncoder = JsonEncoder.withIndent('  ');

  Callback _callback;
  String _cardId;

  @override
  void initState() {
    super.initState();
    TangemSdk.allowsOnlyDebugCards(true);
    _callback = Callback((success) {
      if (success is CardResponse) {
        _cardId = success.cardId;
      }
      try {
        final prettyJson = _jsonEncoder.convert(success.toJson());
        List<String> list =prettyJson.split("\n");//.forEach((element)  print(element));
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=>InfoWidget(list))
        );
      } catch (e) {
        print('The provided string is not valid JSON');
        print(success.toString());
      }
    }, (error) {
      if (error is ErrorResponse) {
        print(error.localizedDescription);
      } else {
        print(error);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 25),
          RowActions(
            [
              ActionButton(text: "Scan card", action: handleScanCard),
              ActionButton(text: "Sign", action: handleSign),
              ActionButton(text: "Canonize", action: handleCanonize),
            ],
          ),
          ActionType("Issuer data"),
          RowActions(
            [
              ActionButton(text: "Read", action: handleReadIssuerData),
              ActionButton(text: "Write", action: handleWriteIssuerData),
            ],
          ),
          ActionType("Issuer extra data"),
          RowActions(
            [
              ActionButton(text: "Read", action: handleReadIssuerExtraData),
              ActionButton(text: "Write", action: handleWriteIssuerExtraData),
            ],
          ),
          ActionType("User data"),
          RowActions(
            [
              ActionButton(text: "Read (all)", action: handleReadUserData),
              ActionButton(text: "Write data", action: handleWriteUserData),
            ],
          ),
          RowActions([
            ActionButton(text: "Write protected data", action: handleWriteUserProtectedData),
          ]),
          ActionType("Wallet"),
          RowActions(
            [
              ActionButton(text: "Create", action: handleCreateWallet),
              ActionButton(text: "Purge", action: handlePurgeWallet),
            ],
          ),

          ActionType("Pins"),
          RowActions(
            [
              ActionButton(text: "Change PIN1", action: handleSetPin1),
              ActionButton(text: "Change PIN2", action: handleSetPin2),
            ],
          ),
          SizedBox(height: 25)
        ],
      ),
    );
  }

  handleScanCard() {
    TangemSdk.allowsOnlyDebugCards(false);
    TangemSdk.scanCard(_callback);
  }

  handleSign() {
  //  final listOfData = List.generate(_utils.randomInt(1, 10), (index) => _utils.randomString(20));
    //final hashes = listOfData.map((e) => e.toHexString()).toList();

    //TangemSdk.sign(_callback, hashes, {TangemSdk.cid: _cardId});
  }

  handleCanonize() {
    final publicKeyHex = "04AD465EA5BB14AD33E493B0F9459AA20C0EFA35A255B5D3E1B134DC8594DAA86A5E1B169B9570A91B4AB9427A739D87BE32D1046954DC8BC39AC3EAFE3AF41F1C";
    final hashHex = "9D8BEF45207B396386C439493488FB30409D5E3A538F5CBC5B062DA0AA138CA9";
    final signatureHex = "C40CA98DB192972849C2CCD37EC8221221868BCAA30567D27DA6DCAAA34A3A33931BFC191C289330BE4D06B597478DB37EC196C010542B92A4BE6BB9E2609532";
    final resultForCheck = "C40CA98DB192972849C2CCD37EC8221221868BCAA30567D27DA6DCAAA34A3A336CE403E6E3D76CCF41B2F94A68B8724B3BED46269EF474A91B13F2D2EDD5AC0F";

    TangemSdk.normalizeVerify(publicKeyHex, hashHex, signatureHex, _callback);
  }

  handleReadIssuerData() {
    TangemSdk.readIssuerData(_callback, {TangemSdk.cid: _cardId});
  }

  handleWriteIssuerData() {
    if (_cardId == null) {
      _showToast("CardId required. Scan your card before proceeding");
      return;
    }

    final issuerData = "Issuer data to be written on a card";
    final issuerDataSignature = "(cardId.bytes + issuerData.bytes + counter.bytes(4)).sign(issuerPrivateKey)";
    final issuerDataCounter = 1;

    TangemSdk.writeIssuerData(_callback, issuerData.toHexString(), issuerDataSignature.toHexString(), {
      TangemSdk.cid: _cardId,
      TangemSdk.issuerDataCounter: issuerDataCounter,
    });
  }

  Map handleReadIssuerExtraData() {
    Map<String,dynamic> map = Map();
    TangemSdk.readIssuerExtraData(_callback,map);
    return map;
  }

  handleWriteIssuerExtraData() {
    if (_cardId == null) {
      _showToast("CardId required. Scan your card before proceeding");
      return;
    }

    final issuerData = "Issuer extra data to be written on a card";
    final startingSignature =
        "(cardId.bytes + counter.bytes(4) + issuerData.bytes.size.bytes(2)).sign(issuerPrivateKey)";
    final finalizingSignature = "(cardId.bytes + issuerData.bytes + counter.bytes(4)).sign(issuerPrivateKey)";
    final counter = 1;

    TangemSdk.writeIssuerExtraData(
        _callback, issuerData.toHexString(), startingSignature.toHexString(), finalizingSignature.toHexString(), {
      TangemSdk.cid: _cardId,
      TangemSdk.issuerDataCounter: counter,
    });
  }

  handleReadUserData() {
    TangemSdk.readUserData(_callback, );//{TangemSdk.cid: _cardId});
  }

  handleWriteUserData() {
    final userData = "User data to be written on a card";
    final userCounter = 1;

    TangemSdk.writeUserData(_callback, userData.toHexString(), {
      TangemSdk.cid: _cardId,
      TangemSdk.userCounter: userCounter,
    });
  }

  handleWriteUserProtectedData() {
    final userProtectedData = "Protected user data to be written on a card";
    final protectedCounter = 1;

    TangemSdk.writeUserProtectedData(_callback, userProtectedData.toHexString(), {
      TangemSdk.cid: _cardId,
      TangemSdk.userProtectedCounter: protectedCounter,
    });
  }

  handleCreateWallet() {
    TangemSdk.createWallet(_callback, {TangemSdk.cid: _cardId});
  }

  handlePurgeWallet() {
    TangemSdk.purgeWallet(_callback, {TangemSdk.cid: _cardId});
  }

  handleSetPin1() {
    TangemSdk.setPinCode(PinType.PIN1, _callback, {TangemSdk.cid: _cardId});
  }

  handleSetPin2() {
    TangemSdk.setPinCode(PinType.PIN2, _callback, {TangemSdk.cid: _cardId});
  }

  _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black.withOpacity(0.8),
      toastLength: Toast.LENGTH_LONG,
    );
  }
}
