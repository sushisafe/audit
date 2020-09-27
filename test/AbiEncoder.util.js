const ethers = require('ethers');

function encodeParameters(types, values) {
    const abi = new ethers.utils.AbiCoder();
    return abi.encode(types, values);
}

const SusafeChef = '0xCaD575B284B78f40cdAb12c0AbDD36b918f1CbBE';

const BAL_97_3_KNC_SUSAFE = '0x9965dfe46ef0edc1557e5d794f67dce62fad22b7';
const BAL_97_3_SASHIMI_SUSAFE = '0x19bb24cfbbd87bf3add4b2caba5077d0b8da6d99';
const BAL_97_3_VALUE_SUSAFE = '0x6ad69f29454114a2b883cda1e4cdb34f9d4f0023';
const BAL_97_3_WBTC_SUSAFE = '0xe2cefefe6bf96585ee198c65d75c6f70a4d4767b';
const BAL_80_20_vUSD_SUSAFE = '0xec1ce403f5214c819ea0d9e7331945c834dec5d0';
const UNIv2_UNI_SUSAFE = '0x75b8bcd265c730554c001ff17813468f83ce8334';
const UNIv2_ETH_SUSAFE = '0x1350287fd810AebAd7a559BDB227c04e7e46738b';

let now = Date.now() / 1000 | 0;
now = (Math.round(now / 100) + 1) * 100;

let lastRewardBlock = 10912000;

contract('AbiEncoder.util', ([alice]) => {
    it('add BAL_97_3_KNC_SUSAFE', async () => {
        console.log('add(uint256,address,bool,uint256)');
        console.log(encodeParameters(['uint256', 'address', 'bool', 'uint256'], ['32000', BAL_97_3_KNC_SUSAFE, false, lastRewardBlock]));
    });

    it('add BAL_97_3_SASHIMI_SUSAFE', async () => {
        const alocPoint = 32000;
        const lpContract = BAL_97_3_SASHIMI_SUSAFE;
        console.log('SusafeChef.add(%d, %s, false, lastRewardBlock)', alocPoint, lpContract);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: add(uint256,address,bool,uint256)');
        console.log('data: %s', encodeParameters(['uint256', 'address', 'bool', 'uint256'], [alocPoint, lpContract, false, lastRewardBlock]));
        console.log('eta: %d', now + 6 * 3600 + 5 * 60);
    });

    it('add BAL_97_3_VALUE_SUSAFE', async () => {
        const alocPoint = 32000;
        const lpContract = BAL_97_3_VALUE_SUSAFE;
        console.log('SusafeChef.add(%d, %s, false, lastRewardBlock)', alocPoint, lpContract);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: add(uint256,address,bool,uint256)');
        console.log('data: %s', encodeParameters(['uint256', 'address', 'bool', 'uint256'], [alocPoint, lpContract, false, lastRewardBlock]));
        console.log('eta: %d', now + 6 * 3600 + 5 * 60);
    });

    it('add BAL_97_3_WBTC_SUSAFE', async () => {
        const alocPoint = 32000;
        const lpContract = BAL_97_3_WBTC_SUSAFE;
        console.log('SusafeChef.add(%d, %s, false, lastRewardBlock)', alocPoint, lpContract);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: add(uint256,address,bool,uint256)');
        console.log('data: %s', encodeParameters(['uint256', 'address', 'bool', 'uint256'], [alocPoint, lpContract, false, lastRewardBlock]));
        console.log('eta: %d', now + 6 * 3600 + 5 * 60);
    });

    it('add BAL_80_20_vUSD_SUSAFE', async () => {
        const alocPoint = 32000;
        const lpContract = BAL_80_20_vUSD_SUSAFE;
        console.log('SusafeChef.add(%d, %s, false, lastRewardBlock)', alocPoint, lpContract);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: add(uint256,address,bool,uint256)');
        console.log('data: %s', encodeParameters(['uint256', 'address', 'bool', 'uint256'], [alocPoint, lpContract, false, lastRewardBlock]));
        console.log('eta: %d', now + 6 * 3600 + 30 * 60);
    });

    it('add UNIv2_UNI_SUSAFE', async () => {
        const alocPoint = 64000;
        const lpContract = UNIv2_UNI_SUSAFE;
        console.log('SusafeChef.add(%d, %s, false, lastRewardBlock)', alocPoint, lpContract);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: add(uint256,address,bool,uint256)');
        console.log('data: %s', encodeParameters(['uint256', 'address', 'bool', 'uint256'], [alocPoint, lpContract, false, lastRewardBlock]));
        console.log('eta: %d', now + 6 * 3600 + 30 * 60);
    });

    it('[1] set pools', async () => {
        // set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        const pids = [0, 3, 5, 7, 8, 9];
        const alocPts = [2000, 2000, 16000, 8000, 16000, 32000];
        for (let i = 0; i < pids.length; i++) {
            const pid = pids[i];
            const alocPoint = alocPts[i];
            console.log('\n========================================================\n');
            console.log('--> queueTransaction: ');
            console.log('SusafeChef.set(%d, %d, false)', pid, alocPoint);
            console.log('target: %s', SusafeChef);
            console.log('value: 0');
            console.log('signature: set(uint256,uint256,bool)');
            console.log('data: %s', encodeParameters(['uint256', 'uint256', 'bool'], [pid, alocPoint, false]));
            console.log('eta: %d', now + 6 * 3600 + 30 * 60);
            console.log('--> executeTransaction: ');
        }
    });

    it('setDelay 24h', async () => {
        const delay = 24 * 3600; // 24h
        // setDelay(uint delay_)
        console.log('\n========================================================\n');
        console.log('--> queueTransaction: ');
        console.log('SusafeChef.setDelay(%d)', delay);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: setDelay(uint256)');
        console.log('data: %s', encodeParameters(['uint256'], [delay]));
        console.log('eta: %d', now + 6 * 3600 + 30 * 60);
        console.log('--> executeTransaction: ');
    });

    it('[2] set pools', async () => {
        // set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        const pids = [9, 8, 2, 0]; // UNI/SUSAFE, VUSD/SUSAFE, YFV, USDC
        const alocPts = [16000, 8000, 2000, 1000];
        for (let i = 0; i < pids.length; i++) {
            const pid = pids[i];
            const alocPoint = alocPts[i];
            console.log('\n========================================================\n');
            console.log('--> queueTransaction: ');
            console.log('SusafeChef.set(%d, %d, false)', pid, alocPoint);
            console.log('target: %s', SusafeChef);
            console.log('value: 0');
            console.log('signature: set(uint256,uint256,bool)');
            console.log('data: %s', encodeParameters(['uint256', 'uint256', 'bool'], [pid, alocPoint, false]));
            console.log('eta: %d', now + 6 * 3600 + 30 * 60);
            console.log('--> executeTransaction: ');
        }
    });

    it('add UNIv2_ETH_SUSAFE', async () => {
        const alocPoint = 64000;
        const lpContract = UNIv2_ETH_SUSAFE;
        console.log('SusafeChef.add(%d, %s, false, lastRewardBlock)', alocPoint, lpContract);
        console.log('target: %s', SusafeChef);
        console.log('value: 0');
        console.log('signature: add(uint256,address,bool,uint256)');
        console.log('data: %s', encodeParameters(['uint256', 'address', 'bool', 'uint256'], [alocPoint, lpContract, false, lastRewardBlock]));
        console.log('eta: %d', now + 6 * 3600 + 30 * 60);
    });

    it('[3] set pools', async () => {
        // set(uint256 _pid, uint256 _allocPoint, bool _withUpdate)
        const pids = [9, 2]; // UNI/SUSAFE, YFV
        const alocPts = [8000, 1000];
        for (let i = 0; i < pids.length; i++) {
            const pid = pids[i];
            const alocPoint = alocPts[i];
            console.log('\n========================================================\n');
            console.log('--> queueTransaction: ');
            console.log('SusafeChef.set(%d, %d, false)', pid, alocPoint);
            console.log('target: %s', SusafeChef);
            console.log('value: 0');
            console.log('signature: set(uint256,uint256,bool)');
            console.log('data: %s', encodeParameters(['uint256', 'uint256', 'bool'], [pid, alocPoint, false]));
            console.log('eta: %d', now + 6 * 3600 + 60 * 60);
            console.log('--> executeTransaction: ');
        }
    });
});
