// lib/services/invoice_service.dart
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order_model.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  static Future<void> generateAndDownloadInvoice(OrderModel order) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with Logo
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SENDY',
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#FF5722'),
                        ),
                      ),
                      pw.Text(
                        'Service de livraison',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'FACTURE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'N° ${order.orderId.substring(0, 8).toUpperCase()}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Client Information
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Informations Client',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text('Nom: ${order.clientName ?? "Client"}'),
                    pw.Text('Téléphone: ${order.clientPhone ?? "N/A"}'),
                    pw.Text('Adresse: ${order.deliveryAddress ?? "N/A"}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Client Comment if exists
              if (order.clientComment != null &&
                  order.clientComment!.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#FFF3E0'),
                    border: pw.Border.all(color: PdfColor.fromHex('#FF5722')),
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(5)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Commentaire du client:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#FF5722'),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        order.clientComment!,
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],

              // Items Table
              pw.Text(
                'Détails de la commande',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              _buildItemsTable(order),
              pw.SizedBox(height: 20),

              // Total Section
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 250,
                  child: pw.Column(
                    children: [
                      _buildTotalRow('Sous-total', order.subtotal),
                      _buildTotalRow('Frais de livraison', order.deliveryFee),
                      _buildTotalRow('Frais de service', order.serviceFee),
                      pw.Divider(thickness: 2),
                      _buildTotalRow(
                        'TOTAL',
                        order.total,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(height: 30),

              // Payment Method
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey200,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Mode de paiement:',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      order.paymentMethod == PaymentMethod.cash
                          ? 'Espèces à la livraison'
                          : 'Carte bancaire',
                    ),
                  ],
                ),
              ),
              pw.Spacer(),

              // Footer
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Merci d\'avoir choisi Sendy!',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // Save and share PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static pw.Widget _buildItemsTable(OrderModel order) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FF5722'),
          ),
          children: [
            _buildTableCell('Article', isHeader: true),
            _buildTableCell('Qté', isHeader: true),
            _buildTableCell('Prix Unit.', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Items
        ...order.items.map((item) => pw.TableRow(
              children: [
                _buildTableCell(item.name),
                _buildTableCell(item.quantity.toString()),
                _buildTableCell('${item.price.toStringAsFixed(2)} DHs'),
                _buildTableCell(
                    '${(item.price * item.quantity).toStringAsFixed(2)} DHs'),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildTotalRow(String label, double amount,
      {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            '${amount.toStringAsFixed(2)} DHs',
            style: pw.TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isTotal ? PdfColor.fromHex('#FF5722') : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }
}
