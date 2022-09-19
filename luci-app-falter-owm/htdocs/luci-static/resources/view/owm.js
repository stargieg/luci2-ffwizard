'use strict';
'require uci';
'require view';

return view.extend({
    handleSave: null,
    handleReset: null,
    handleSaveApply: null,
    load: () => {
        return Promise.all([
            uci.load('system').then(() => {
                return uci.sections('system', 'system');
            })
        ])
    },
    render: (data) => {
        let hasLatLon = false;
        data[0].forEach(section => {
            let lat = uci.get_first('system', 'system', 'latitude');
            let lon = uci.get_first('system', 'system', 'longitude');
        });
        return E([], {}, [
            E('iframe', {'id': 'mapframe', 'style': 'width:100%; height:640px; border:none', 'src': L.resource('owm.htm')})
        ]);
    }
})
