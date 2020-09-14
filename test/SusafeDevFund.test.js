const {expectRevert, time} = require('@openzeppelin/test-helpers');

const testUtils = require('./test.utils');
const SusafeToken = artifacts.require('SusafeToken');
const SusafeDevFund = artifacts.require('SusafeDevFund');

contract('SusafeToken', ([alice, bob, carol]) => {
    const founder1 = '0xEDCD0Ef9292bd9C9d93D98a05256f86C9A3f2503';
    const founder9 = '0xF7a787aF28793A758986E103780cBd5B1549F98d';

    beforeEach(async () => {
        this.susafe = await SusafeToken.new({from: alice});
        this.devFund = await SusafeDevFund.new(this.susafe.address, {from: alice});
        await this.susafe.setDev(this.devFund.address, {from: alice});
        console.log('susafe address = %s', this.susafe.address);
        console.log('devFund address = %s', this.devFund.address);
        console.log('susafe\'s dev = %s', await this.susafe.dev());
    });

    it('mint 21k SUSAFE to dev fund', async () => {
        await this.susafe.mint(this.devFund.address, '21000000000000000000000', {from: alice});
        const totalSupply = await this.susafe.totalSupply();
        const aliceBal = await this.susafe.balanceOf(alice);
        const devFundBal = await this.susafe.balanceOf(this.devFund.address);
        assert.equal(totalSupply.valueOf(), '21000000000000000000000');
        assert.equal(aliceBal.valueOf(), '0');
        assert.equal(devFundBal.valueOf(), '21000000000000000000000');
    });

    it('SusafeDevFund.claimRewards()', async () => {
        // await this.susafe.mint(this.devFund.address, '21000000000000000000000', {from: alice});
        console.log('susafe\'s totalSupply = %s', await this.susafe.totalSupply());
        const devFundBal = await this.susafe.balanceOf(this.devFund.address);
        console.log('devFundBal = %s SUSAFE', testUtils.fromWei(devFundBal));
        for (let i = 0; i < 5; i++) {
            await time.increase(3600);
            console.log('claimableRewards = %s SUSAFE', testUtils.fromWei(await this.devFund.claimableRewards()));
        }
        const amount = await this.devFund.claimableRewards();
        await this.devFund.claimRewards({from: bob});
        let founder1Bal = await this.susafe.balanceOf(founder1);
        let founder9Bal = await this.susafe.balanceOf(founder9);
        // assert.equal(founder1Bal.valueOf(), amount.valueOf() / 10);
        // assert.equal(founder9Bal.valueOf(), amount.valueOf() / 10 * 3);
        await time.increase(22 * 7 * 24 * 3600);
        await this.devFund.setFounder(8, '0x000000000000000000000000000000000000dead');
        await this.devFund.claimRewards({from: bob});
        founder1Bal = await this.susafe.balanceOf(founder1);
        founder9Bal = await this.susafe.balanceOf(founder9);
        // assert.equal(founder1Bal.valueOf(), '2099999999999999999999');
        // assert.equal(founder9Bal.valueOf(), '2099999999999999999999');
        console.log('susafe\'s totalSupply = %s', await this.susafe.totalSupply());
    });
});

// 000000000000000000