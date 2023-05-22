import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:pemesanan_makanan/api/globlas.dart';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future getMenu() async {
    var response = await http.get(Uri.parse(baseURL + 'menus'));
    print({"m": json.decode(response.body)});
    return {"m": json.decode(response.body)};
  }

  // Future getVouchers() async {
  //   var response = await http.get(Uri.parse(baseURL + 'vouchers'));
  //   print({"v": json.decode(response.body)});
  //   return {"v": json.decode(response.body)};
  // }

  var sum = 0;
  var message = '';
  dynamic harga = 0;
  dynamic statusPesanan = "BELUM_PESAN";
  dynamic voucherCode = "";
  dynamic voucherDiscount = 0;
  List<int> id = [];
  List<int> count = [];
  List<num> countPrice = [];
  List<String> listCatatan = [];
  dynamic voucherError = "";
  dynamic currentOrderId = "";

  @override
  void initState() {
    super.initState();
    getMenu().then((data) {
      setState(() {
        count = List<int>.filled(data['m']['datas'].length, 0);
        countPrice = List<double>.filled(data['m']['datas'].length, 0.00);
        listCatatan = List<String>.filled(data['m']['datas'].length, "");
      });
    });
    // postOrder();
    // validateVoucher(voucherCode);
  }

  void _incrementCount(int index, double harga) {
    setState(() {
      count[index]++;
      countPrice[index] = double.parse('${count[index]}') * harga;
    });
  }

  void _decrementCount(int index, double harga) {
    setState(() {
      if (count[index] > 0) {
        count[index]--;
        countPrice[index] = double.parse('${count[index]}') * harga;
      }
    });
  }

  // void _totalBayar() {
  //   setState(() {
  //     sum = count * 10000;
  //   });
  // }
  final numberFormatter = new NumberFormat("#,##0", "id_ID");

  var _controller = TextEditingController();

  Future validateVoucher(value) async {
    var response =
        await http.get(Uri.parse(baseURL + 'vouchers?kode=${value}'));
    var data = json.decode(response.body);
    print({"v": data});
    var vouchers = data['datas'];
    if (data["status_code"] == 200) {
      setState(() {
        voucherDiscount = value != "" ? vouchers["nominal"] : 0;
      });
    } else {
      setState(() {
        voucherDiscount = 0;
      });
    }
    return data;
  }

  Future postOrder() async {
    final List fixedList = Iterable<int>.generate(count.length).toList();
    dynamic finalData = fixedList
        .map(
          (e) {
            return {
              "id": e + 1,
              "harga": countPrice[e],
              "catatan": listCatatan[e] != "" ? listCatatan[e] : "-"
            };
          },
        )
        .toList()
        .where((element) => element["harga"] > 0)
        .toList();
    print("ALOHA: ${finalData}");

    // final List<Map<String, dynamic>> items = [
    //   {"id": 1, "harga": 11000, "catatan": listCatatan.toString()},
    // ];

    final orderData = {
      "nominal_diskon": "${voucherDiscount}",
      "nominal_pesanan":
          "${countPrice.sum - voucherDiscount > 0 ? countPrice.sum - voucherDiscount : 0}",
      "items": finalData
    };

    final body = json.encode(orderData);
    final response = await http.post(Uri.parse(baseURL + 'order'),
        body: body, headers: {"Content-Type": "application/json"});
    print("RESULT: ${response.body}");
    var data = json.decode(response.body);
    if (data["status_code"] == 200) {
      setState(() {
        currentOrderId = data["id"];
      });
    }

    return json.decode(response.body);
  }

  Future cancelOrder() async {
    final response = await http.post(
        Uri.parse(baseURL + 'order/cancel/${currentOrderId}'),
        headers: {"Content-Type": "application/json"});
    print("RESULT: ${response.body}");
    var data = json.decode(response.body);
    if (data["status_code"] == 200) {
      // CLEAR DATA
      await getMenu().then((data) {
        setState(() {
          count = List<int>.filled(data['m']['datas'].length, 0);
          countPrice = List<double>.filled(data['m']['datas'].length, 0.00);
          listCatatan = List<String>.filled(data['m']['datas'].length, "");
        });
      });
      return json.decode(response.body);
    } else {
      return "NOT OK";
    }
  }

  handleCatat(int index, String catatan) {
    listCatatan[index] = catatan;
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    var safeArea = MediaQuery.of(context).padding.top;
    // getMenu();
    return SafeArea(
      child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder(
                  future: getMenu(),
                  builder:
                      (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    if (snapshot.hasData) {
                      print(snapshot.data['m']['datas'].length);

                      return Container(
                        height: height - (safeArea + 171),
                        child: ListView.builder(
                            itemCount: snapshot.data['m']['datas'].length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(
                                    left: 20, right: 20, top: 8, bottom: 8),
                                child: Container(
                                  foregroundDecoration: BoxDecoration(
                                      color: (statusPesanan != "DIPROSES" ||
                                              (statusPesanan == "DIPROSES" &&
                                                  count[index] > 0))
                                          ? Colors.black.withOpacity(0)
                                          : Color.fromARGB(255, 110, 110, 110)
                                              .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Card(
                                    elevation: 3,
                                    color: Color(0xfff6f6f6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Container(
                                            width: 75,
                                            height: 75,
                                            decoration: BoxDecoration(
                                                color: Colors.black12,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                                image: DecorationImage(
                                                    fit: BoxFit.contain,
                                                    image: NetworkImage(snapshot
                                                        .data['m']['datas']
                                                            [index]['gambar']
                                                        .toString()))),
                                          ),
                                        ),
                                        Expanded(
                                          child:
                                              //
                                              Padding(
                                            padding: const EdgeInsets.only(
                                                top: 16.0, bottom: 10),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                // Padding(padding: EdgeInsets.only(top: 10)),
                                                Text(
                                                  snapshot.data['m']['datas']
                                                      [index]['nama'],
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Rp ${numberFormatter.format(snapshot.data['m']['datas'][index]['harga'])}',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                              color: Color(
                                                                  0xff009aad),
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                  ],
                                                ),

                                                Visibility(
                                                  maintainSize: true,
                                                  maintainAnimation: true,
                                                  maintainState: true,
                                                  visible: (statusPesanan !=
                                                              "DIPROSES" ||
                                                          (statusPesanan ==
                                                                  "DIPROSES" &&
                                                              listCatatan[
                                                                      index] !=
                                                                  ""))
                                                      ? true
                                                      : false,
                                                  child: SizedBox(
                                                    height: 35,
                                                    child: TextField(
                                                      onChanged: (value) {
                                                        handleCatat(
                                                            index, value);
                                                      },
                                                      textAlignVertical:
                                                          TextAlignVertical
                                                              .center,
                                                      decoration:
                                                          InputDecoration(
                                                              icon: Icon(
                                                                  Icons.notes),
                                                              hintText:
                                                                  'Catatan',
                                                              border:
                                                                  InputBorder
                                                                      .none),
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                        IntrinsicHeight(
                                          child: Row(
                                            children: [
                                              Visibility(
                                                maintainSize: true,
                                                maintainAnimation: true,
                                                maintainState: true,
                                                visible:
                                                    statusPesanan == "DIPROSES",
                                                child: VerticalDivider(
                                                  width: 0,
                                                  thickness: 2,
                                                ),
                                              ),
                                              Visibility(
                                                maintainSize: true,
                                                maintainAnimation: true,
                                                maintainState: true,
                                                visible:
                                                    statusPesanan != "DIPROSES",
                                                child: IconButton(
                                                    color: Color(0xff009aad),
                                                    onPressed: () {
                                                      snapshot.data['m']
                                                              ['datas'][index]
                                                          ['id'];

                                                      var harga =
                                                          snapshot.data['m']
                                                                  ['datas']
                                                              [index]?["harga"];

                                                      _decrementCount(
                                                          index,
                                                          double.parse(harga
                                                              .toString()));
                                                      // snapshot.data['m']['datas'][index]['id'];
                                                    },
                                                    icon: Icon(Icons
                                                        .indeterminate_check_box_outlined)),
                                              ),
                                              Visibility(
                                                maintainSize: true,
                                                maintainAnimation: true,
                                                maintainState: true,
                                                visible: (statusPesanan !=
                                                        "DIPROSES" ||
                                                    (statusPesanan ==
                                                            "DIPROSES" &&
                                                        count[index] > 0)),
                                                child: Text(
                                                  '${count.length > 0 ? count[index] : 0}',
                                                  textAlign: TextAlign.left,
                                                  style: GoogleFonts.montserrat(
                                                    color: Color(0xff009aad),
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                maintainSize: true,
                                                maintainAnimation: true,
                                                maintainState: true,
                                                visible:
                                                    statusPesanan != "DIPROSES",
                                                child: IconButton(
                                                    color: Color(0xff009aad),
                                                    onPressed: () {
                                                      var harga =
                                                          snapshot.data['m']
                                                                  ['datas']
                                                              [index]?["harga"];
                                                      _incrementCount(
                                                          index,
                                                          double.parse(harga
                                                              .toString()));
                                                    },
                                                    icon: Icon(Icons.add_box)),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                      );
                    } else {
                      return Center(
                        child: Text("Tidak ada"),
                      );
                    }
                    // }
                  },
                ),
                Stack(children: [
                  LayoutBuilder(builder:
                      (BuildContext context, BoxConstraints constraints) {
                    return Container(
                      width: width,
                      height: 171,
                      decoration: BoxDecoration(
                          color: Color(0xfff0f0f0),
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30))),
                      child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: 'Total Pesanan',
                                          style: GoogleFonts.montserrat(
                                              // color: Colors.black54,
                                              color: Color(0xff2e2e2e),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: ' (${count.sum} Menu) : ',
                                          style: GoogleFonts.montserrat(
                                              color: Color(0xff2e2e2e),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w400),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                      'Rp ${numberFormatter.format(countPrice.sum)}',
                                      textAlign: TextAlign.left,
                                      style: GoogleFonts.montserrat(
                                          color: Color(0xff009aad),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700))
                                ],
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 5),
                                child: Divider(
                                  thickness: 2,
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                          "assets/images/voucher_icon.png",
                                          scale: 3.5),
                                      SizedBox(width: 12),
                                      Text(
                                        'Voucher',
                                        textAlign: TextAlign.left,
                                        style: GoogleFonts.montserrat(
                                            color: Color(0xff2e2e2e),
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),

                                  GestureDetector(
                                    onTap: () {
                                      showModalBottomSheet<void>(
                                          barrierColor: Colors.transparent,
                                          context: context,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(25.0),
                                            ),
                                          ),
                                          isScrollControlled: true,
                                          builder: (BuildContext context) {
                                            return Padding(
                                              padding: EdgeInsets.only(
                                                  bottom: MediaQuery.of(context)
                                                      .viewInsets
                                                      .bottom),
                                              child: Container(
                                                height: 200,
                                                decoration: BoxDecoration(
                                                    color: Color(0xffffffff),
                                                    borderRadius:
                                                        BorderRadius.only(
                                                            topLeft: Radius
                                                                .circular(30),
                                                            topRight:
                                                                Radius.circular(
                                                                    30))),
                                                child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Image.asset(
                                                              "assets/images/voucher_icon.png",
                                                              scale: 3.5),
                                                          SizedBox(width: 12),
                                                          Text(
                                                            'Punya kode voucher?',
                                                            textAlign:
                                                                TextAlign.left,
                                                            style: GoogleFonts.montserrat(
                                                                color: Color(
                                                                    0xff2e2e2e),
                                                                fontSize: 23,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ],
                                                      ),
                                                      SizedBox(
                                                        height: 5,
                                                      ),
                                                      Text(
                                                        'Masukkan kode voucher di sini',
                                                        textAlign:
                                                            TextAlign.left,
                                                        style: GoogleFonts
                                                            .montserrat(
                                                                color: Color(
                                                                    0xff2e2e2e),
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                      ),
                                                      SizedBox(
                                                        height: 15,
                                                      ),
                                                      TextField(
                                                        controller: _controller,
                                                        // onChanged: (value) {
                                                        //   setState(() {
                                                        //     voucherCode = value;
                                                        //   });
                                                        // },
                                                        decoration:
                                                            InputDecoration(
                                                          enabledBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff009aad)),
                                                          ),
                                                          focusedBorder:
                                                              UnderlineInputBorder(
                                                            borderSide: BorderSide(
                                                                color: Color(
                                                                    0xff009aad)),
                                                          ),
                                                          hintText:
                                                              'Kode Voucher',
                                                          suffixIcon:
                                                              IconButton(
                                                            onPressed:
                                                                () async {
                                                              setState(() {
                                                                voucherCode =
                                                                    "";
                                                                _controller
                                                                    .clear();
                                                                voucherDiscount =
                                                                    0;
                                                              });

                                                              await validateVoucher(
                                                                  "");
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            icon: Icon(
                                                                Icons.cancel),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 15,
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          SizedBox(
                                                            height: 40,
                                                            width: 200,
                                                            child: ElevatedButton(
                                                                style: ButtonStyle(
                                                                    backgroundColor: MaterialStateProperty.all<Color>(Color(0xff009aad)),
                                                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              25.0),
                                                                    ))),
                                                                onPressed: () async {
                                                                  setState(() {
                                                                    // if (voucherCode == _controller.text) {
                                                                    voucherCode =
                                                                        _controller
                                                                            .text;
                                                                  });
                                                                  var res = await validateVoucher(
                                                                      _controller
                                                                          .text);
                                                                  Navigator.pop(
                                                                      context);
                                                                  if (res["status_code"] !=
                                                                      200) {
                                                                    ScaffoldMessenger.of(
                                                                            context)
                                                                        .showSnackBar(SnackBar(
                                                                            content:
                                                                                Text(res["message"])));
                                                                  }
                                                                },
                                                                child: Text("Validasi Voucher")),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          });
                                    },
                                    child: voucherDiscount == 0
                                        ? Row(
                                            children: [
                                              Text("Input Voucher",
                                                  style: GoogleFonts.montserrat(
                                                      color: Color(0xffc0c0c0),
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w400)),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: Color(0xffc0c0c0),
                                              )
                                            ],
                                          )
                                        : Row(
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(voucherCode,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                              color: Color(
                                                                  0xffc0c0c0),
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w400)),
                                                  Text(
                                                      'Rp ${numberFormatter.format(voucherDiscount)}',
                                                      textAlign: TextAlign.left,
                                                      style: GoogleFonts
                                                          .montserrat(
                                                              color: Color(
                                                                  0xffe42313),
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700))
                                                ],
                                              ),
                                              Icon(
                                                Icons.arrow_forward_ios,
                                                color: Color(0xffc0c0c0),
                                              )
                                            ],
                                          ),
                                  )
                                  //         });
                                  //   } else {
                                  //     return Text('Wait...');
                                  //   }
                                  // })
                                ],
                              )
                            ],
                          )),
                    );
                  }),
                  Positioned(
                    bottom: 0,
                    child: LayoutBuilder(builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return Container(
                        width: width,
                        height: 65,
                        decoration: BoxDecoration(
                            color: Color(0xffffffff),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30))),
                        child: Padding(
                            padding: const EdgeInsets.only(
                                bottom: 10, left: 20, right: 20, top: 15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                            "assets/images/order_cart_icon.png",
                                            scale: 3),
                                        SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Pembayaran',
                                              textAlign: TextAlign.left,
                                              style: GoogleFonts.montserrat(
                                                  color: Color(0xffc0c0c0),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            Text(
                                                'Rp ${numberFormatter.format(voucherDiscount != 0 ? (countPrice.sum - voucherDiscount > 0 ? countPrice.sum - voucherDiscount : 0) : countPrice.sum)}',
                                                textAlign: TextAlign.left,
                                                style: GoogleFonts.montserrat(
                                                    color: Color(0xff009aad),
                                                    fontSize: 20,
                                                    fontWeight:
                                                        FontWeight.w700))
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 35,
                                      child: ElevatedButton(
                                          style: ButtonStyle(
                                              backgroundColor:
                                                  MaterialStateProperty.all<
                                                      Color>(Color(0xff009aad)),
                                              shape: MaterialStateProperty.all<
                                                      RoundedRectangleBorder>(
                                                  RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25.0),
                                              ))),
                                          onPressed: () async {
                                            if (statusPesanan ==
                                                "BELUM_PESAN") {
                                              setState(() {
                                                statusPesanan = "DIPROSES";
                                                postOrder();
                                              });
                                              var res = await postOrder();
                                              if (res["status_code"] == 200) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(SnackBar(
                                                        content: Text(
                                                            res["message"])));
                                              }
                                            } else if (statusPesanan ==
                                                "DIPROSES") {
                                              await showDialog<void>(
                                                barrierDismissible: true,
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                    content: Row(children: [
                                                      Icon(
                                                        Icons
                                                            .warning_amber_rounded,
                                                        color:
                                                            Color(0xff009aad),
                                                        size: 70,
                                                      ),
                                                      SizedBox(
                                                        width: 10,
                                                      ),
                                                      Flexible(
                                                        child: Text(
                                                            "Apakah Anda yakin ingin membatalkan pesanan ini?",
                                                            style: GoogleFonts
                                                                .montserrat(
                                                                    fontSize:
                                                                        18,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w400)),
                                                      )
                                                    ]),
                                                    actions: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                bottom: 20),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            SizedBox(
                                                              height: 35,
                                                              width: 100,
                                                              child: ElevatedButton(
                                                                  style: ButtonStyle(
                                                                      backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(25.0),
                                                                          side: BorderSide(
                                                                            width:
                                                                                1.0,
                                                                            color:
                                                                                Color(0xff009aad),
                                                                          )))),
                                                                  onPressed: () {
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                    "Batal",
                                                                    style: TextStyle(
                                                                        color: Color(
                                                                            0xff009aad)),
                                                                  )),
                                                            ),
                                                            SizedBox(width: 20),
                                                            SizedBox(
                                                              height: 35,
                                                              width: 100,
                                                              child: ElevatedButton(
                                                                  style: ButtonStyle(
                                                                      backgroundColor: MaterialStateProperty.all<Color>(Color(0xff009aad)),
                                                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(RoundedRectangleBorder(
                                                                          borderRadius: BorderRadius.circular(25.0),
                                                                          side: BorderSide(
                                                                            width:
                                                                                1.0,
                                                                            color:
                                                                                Color(0xff009aad),
                                                                          )))),
                                                                  onPressed: () async {
                                                                    var res =
                                                                        await cancelOrder();
                                                                    if (res["status_code"] ==
                                                                        200) {
                                                                      setState(
                                                                          () {
                                                                        statusPesanan =
                                                                            "BELUM_PESAN";
                                                                        Navigator.pop(
                                                                            context);
                                                                      });
                                                                      ScaffoldMessenger.of(
                                                                              context)
                                                                          .showSnackBar(
                                                                              SnackBar(content: Text(res["message"])));
                                                                    }
                                                                  },
                                                                  child: Text(
                                                                    "Yakin",
                                                                    style: TextStyle(
                                                                        color: Color(
                                                                            0xffffffff)),
                                                                  )),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            }

                                            print(listCatatan);
                                          },
                                          child: Text(
                                              statusPesanan != "DIPROSES"
                                                  ? "Pesan Sekarang"
                                                  : "Batalkan")),
                                    )
                                  ],
                                )
                              ],
                            )),
                      );
                    }),
                  ),
                ])
              ],
            ),
          )),
    );
  }
}
