import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:fryo/src/logic/payment_method_provider.dart';
import 'package:provider/provider.dart';

import '../entity/entities.dart' as atomi;
import '../logic/address_provider.dart';
import '../widget/util.dart';
import 'address_selector.dart';

class NewPaymentMethodDialog extends StatefulWidget {
  const NewPaymentMethodDialog({Key? key}) : super(key: key);

  @override
  _NewPaymentMethodDialogState createState() => _NewPaymentMethodDialogState();
}

class _NewPaymentMethodDialogState extends State<NewPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = CardFormEditController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late atomi.Address _selectedBillingAddress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedBillingAddress = Provider.of<AddressProvider>(context).billingAddress;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('New Payment Method'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CardFormField(
                controller: _controller,
                countryCode: 'US',
                style: CardFormStyle(
                  borderColor: Colors.blueGrey,
                  textColor: Colors.black,
                  fontSize: 14,
                  borderRadius: 10,
                  borderWidth: 4,
                  placeholderColor: Colors.blue,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final newSelectedAddress = await showDialog<atomi.Address>(
                    context: context,
                    builder: (context) => AddressSelector(),
                  );
                  if (newSelectedAddress == null) {
                    return;
                  }
                  print('xfguo: new selectedBillingAddress: ${newSelectedAddress}');
                  setState(() {
                    _selectedBillingAddress = newSelectedAddress;
                  });
                },
                child: ListTile(
                  leading: Icon(Icons.location_on),
                  title: Text('Billing Address'),
                  subtitle: getAddressText(_selectedBillingAddress),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter email';
                    }
                    return null;
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Phone',
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter phone';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Save'),
          onPressed: () {
            if (_controller.details.complete) {
              _handlePayPress(context);
            }
          },
        ),
      ],
    );
  }

  void _handlePayPress(BuildContext context) async {
    print('xfguo: _handlePayPress, ${_controller}');

    final billingDetails = BillingDetails(
      email: 'email@stripe.com',
      phone: '+48888000888',
      address: Address(
        city: 'Houston',
        country: 'US',
        line1: '1459  Circle Drive',
        line2: '',
        state: 'Texas',
        postalCode: '77063',
      ),
    ); // mocked data for tests

    final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: billingDetails,
          ),
        ));

    final pmProvider = Provider.of<AtomiPaymentMethodProvider>(context, listen: false);
    pmProvider.addPaymentMethod(paymentMethod.id);

    // pop the current page
    Navigator.pop(context, '123');
  }
}
