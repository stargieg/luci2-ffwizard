'use strict';
'require rpc';
'require view';
'require poll';
'require network'

const css = '\
    #infoTable > tr > .td {\
        border-top: unset;\
    }\
';

var getSystemInfo = rpc.declare({
    object: 'system',
    method: 'info',
    expect: {}
});

var getSystemBoard = rpc.declare({
    object: 'system',
    method: 'board',
    expect: {}
});

function extractWifiInformation(results) {
    let wifiArray = [];
    results.forEach(result => {
        wifiArray.push({
            'signalPercent': result.getSignalPercent(),
            'noise': result.getNoise(),
            'signal': result.getSignal(),
            'bitRate': (result.getBitRate() != null) ? result.getBitRate() + ' Mb/s' : '',
            'ssid': (result.getMode() != 'mesh') ? result.getSSID() : result.getMeshID(),
            'bssid': result.getActiveBSSID(),
            'channel': result.getChannel(),
            'mode': result.getMode(),
            'txpower': result.getTXPower() + ' dbm',
            'wifiDevice': result.getDevice().getName()
        });
    });
    return wifiArray;
}

function secondsToDhms(seconds) {
    seconds = Number(seconds);
    var d = Math.floor(seconds / (3600*24));
    var h = Math.floor(seconds % (3600*24) / 3600);
    var m = Math.floor(seconds % 3600 / 60);
    var s = Math.floor(seconds % 60);
    
    var dDisplay = d > 0 ? d + (d == 1 ? ' ' + _('day') + ', ' : ' ' + _('days') + ', ') : '';
    var hDisplay = h > 0 ? h + (h == 1 ? ' ' + _('hour') + ', ' : ' ' + _('hours') + ', ') : '';
    var mDisplay = m > 0 ? m + (m == 1 ? ' ' + _('minute') + ', ' : ' ' + _('minutes') + ', ') : '';
    var sDisplay = s > 0 ? s + (s == 1 ? ' ' + _('second') + '' : ' ' + _('seconds')) : '';
    return dDisplay + hDisplay + mDisplay + sDisplay;
}

function createSystemTable(systemInfo, systemBoard) {
    let tableData = [];
    let memory = `${(systemInfo.memory.total / 1024 / 1024).toFixed(2)} MB (
        ${((systemInfo.memory.total - systemInfo.memory.free) / 1024 / 1024).toFixed(2)} ${_('used')}, 
        ${(systemInfo.memory.free / 1024 / 1024).toFixed(2)} ${_('free')}, 
        ${(systemInfo.memory.buffered / 1024 / 1024).toFixed(2)} ${_('buffered')})`;
    tableData.push([_('System'), systemBoard.system]);
    tableData.push([_('Model'), systemBoard.model]);
    tableData.push([_('Load'), systemInfo.load.map(n => (n/65535).toFixed(2)).join(', ')]);
    tableData.push([_('Memory'), memory]);
    tableData.push([_('Local Time'), new Date(systemInfo.localtime * 1000)]);
    tableData.push([_('Uptime'), secondsToDhms(systemInfo.uptime)]);
    return tableData;
}

function createWifiTable(wifiArray) {
    let tableData = [];
    wifiArray.forEach(wifi => {
        let icon;
        if (wifi.signalPercent == null || wifi.signalPercent <= 0)
				icon = E([]);
			else if (wifi.signalPercent < 25)
                icon = E('img', {'src': L.resource('icons/signal-0-25.png'), 'title': 'Signal: '+ wifi.signal +' db / Noise: ' + wifi.noise + ' db', 'alt': 'Signal Quality'});
			else if (wifi.signalPercent < 50)
                icon = E('img', {'src': L.resource('icons/signal-25-50.png'), 'title': 'Signal: '+ wifi.signal +' db / Noise: ' + wifi.noise + ' db', 'alt': 'Signal Quality'});
			else if (wifi.signalPercent < 75)
                icon = E('img', {'src': L.resource('icons/signal-50-75.png'), 'title': 'Signal: '+ wifi.signal +' db / Noise: ' + wifi.noise + ' db', 'alt': 'Signal Quality'});
			else
                icon = E('img', {'src': L.resource('icons/signal-75-100.png'), 'title': 'Signal: '+ wifi.signal +' db / Noise: ' + wifi.noise + ' db', 'alt': 'Signal Quality'});

        tableData.push([
            icon,
            wifi.bitRate,
            wifi.ssid,
            wifi.bssid,
            wifi.channel,
            wifi.mode,
            wifi.txpower,
            wifi.wifiDevice
        ])
    });
    return tableData;
}

return view.extend({                                                                                      
    handleSaveApply: null,                                                                                
    handleSave: null,                                                                                     
    handleReset: null,                                                                                    
    render: (data) => {                                                                                   
        var infoTable = E('table', { 'class': 'table' }, [                                                
                E('tr', { 'class': 'tr table-titles' }, [                                                 
                        E('th', { 'class': 'th col-1 middle left' }),                                     
                        E('th', { 'class': 'th col-2 middle left' })                                      
                ])                                                                                        
        ]);                                                                                               
        var wirelessTable = E('table', { 'class': 'table' });                                             
        wirelessTable.appendChild(E('tr', { 'class': 'tr table-titles' }, [                           
            E('th', { 'class': 'th col-1' }, _('Signal')),                                                
            E('th', { 'class': 'th col-2' }, _('Bitrate')),                                               
            E('th', { 'class': 'th col-3 middle left' }, _('SSID')),                                      
            E('th', { 'class': 'th col-4' }, _('BSSID')),                                                 
            E('th', { 'class': 'th col-5' }, _('Channel')),                                               
            E('th', { 'class': 'th col-6' }, _('Mode')),                                                  
            E('th', { 'class': 'th col-7' }, _('TX') + '-' + _('Power')),                                 
            E('th', { 'class': 'th col-8' }, _('Interface'))                                              
        ]));                                                                                              
        poll.add(() => {                                                                                  
            Promise.all([                                                                                 
                getSystemInfo(),                                                                          
                getSystemBoard(),                                                                         
                network.getWifiNetworks()                                                                 
            ]).then((results) => {                                                                        
                cbi_update_table(infoTable, createSystemTable(results[0], results[1]));                                                                         
                cbi_update_table(wirelessTable, createWifiTable(extractWifiInformation(results[2])));     
            })                                                                                                                                                  
        }, 30);                                                                                           
        return E([], {}, [                                                                                                                                      
            infoTable,    
            wirelessTable        
        ]);                   
    }                                       
});
