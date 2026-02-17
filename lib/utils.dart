import 'package:battery_saved/battery_api.dart';
import 'package:battery_saved/compliance_config.dart';
import 'package:battery_saved/oem_confirmations_store.dart';

class Utils {

  Future<void> init() async {
    // setState(() => _loading = true);
    final cfg = await ComplianceConfig.loadAsset();
    final st = await BatteryComplianceApi.status();
    final profile = cfg.resolveForFlexible(
      manufacturer: st.manufacturer,
      brand: st.brand,
      model: st.model,
    );

    final confirmed = await OemConfirmationsStore.getConfirmedIds(
      configVersion: cfg.version,
      profileId: profile.id,
    );

    print(  '--------------- $confirmed' );
    print(  '--------------- $cfg' );
    print(  '--------------- ${cfg.version}');
    print(  '--------------- ${st.brand}' );
    print(  '--------------- ${st.model}' );

    // setState(() {
    //   _config = cfg;
    //   _status = st;
    //   _profile = profile;
    //   _confirmed = confirmed;
    //   _loading = false;
    // });
  }

}
