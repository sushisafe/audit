const Web3Utils = require('web3-utils');

module.exports = {
    ADDRESS_ZERO: '0x0000000000000000000000000000000000000000',
    ADDRESS_DEAD: '0x000000000000000000000000000000000000dead',

    expectThrow: async promise => {
        try {
            await promise;
        } catch (error) {
            return;
        }
        assert.fail('Expected throw not received');
    },

    toWei: function (num, decimals = 18) {
        if (decimals == 18) return Web3Utils.toWei(String(num), 'ether');
        else return (Number.parseFloat(num) * Math.pow(10, decimals)).toFixed(0);
    },

    fromWei: function (num, decimals = 18) {
        if (decimals == 18) return Web3Utils.fromWei(num, 'ether');
        else return (Number.parseFloat(num) / Math.pow(10, decimals)).toFixed(4);
    },

    toBN: function (num) {
        return Web3Utils.toBN(num);
    }
};
