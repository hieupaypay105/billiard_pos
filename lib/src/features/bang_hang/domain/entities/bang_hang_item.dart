import 'package:equatable/equatable.dart';

/// Domain entity for a row in Bang Hang table.
class BangHangItem extends Equatable {
  const BangHangItem({
    required this.id,
    required this.project,
    required this.area,
    required this.code,
    required this.type,
    required this.handoverStatus,
    required this.direction,
    required this.acreage,
    required this.constructionArea,
    required this.price,
    required this.tts,
    required this.proceduresSign,
    required this.bankBasket,
    required this.status,
    required this.agent,
    required this.loan,
    this.landSize,
    this.investmentFund,
    this.note,
    this.contractPrice,
    this.fee,
    this.unitPrice,
    this.telesale,
    this.cuttingRatio,
    this.hostName,
    this.phone,
    this.createdAt,
    this.saleId,
    this.ptgLink,
    this.pointLink,
    this.warrantyPolicy,
    this.gift,
    this.depositStatus,
    this.updateDay,
    this.isSelled,
    this.tttd,
    this.saleBonus,
  });

  final String id;
  final String project;
  final String area;
  final String code;
  final String type;
  final String handoverStatus;
  final String direction;
  final String? landSize;
  final String acreage;
  final String constructionArea;
  final String price;
  final String tts;
  final String proceduresSign;
  final String? investmentFund;
  final String bankBasket;
  final String status;
  final String agent;
  final String loan;
  final String? note;
  final String? contractPrice;
  final String? fee;
  final String? unitPrice;
  final String? telesale;
  final String? cuttingRatio;
  final String? hostName;
  final String? phone;
  final String? createdAt;
  final String? saleId;
  final String? ptgLink;
  final String? pointLink;
  final String? warrantyPolicy;
  final String? gift;
  final String? depositStatus;
  final String? updateDay;
  final String? isSelled;
  final String? tttd;
  final String? saleBonus;

  @override
  List<Object?> get props => [
    id,
    project,
    area,
    code,
    type,
    handoverStatus,
    direction,
    landSize,
    acreage,
    constructionArea,
    price,
    tts,
    proceduresSign,
    investmentFund,
    bankBasket,
    status,
    agent,
    loan,
    note,
    contractPrice,
    fee,
    unitPrice,
    telesale,
    cuttingRatio,
    hostName,
    phone,
    createdAt,
    saleId,
    ptgLink,
    pointLink,
    warrantyPolicy,
    gift,
    depositStatus,
    updateDay,
    isSelled,
    tttd,
    saleBonus,
  ];
}
