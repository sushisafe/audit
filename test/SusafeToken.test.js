const {expectRevert} = require('@openzeppelin/test-helpers');
const SusafeToken = artifacts.require('SusafeToken');

contract('SusafeToken', ([alice, bob, carol]) => {
    beforeEach(async () => {
        this.susafe = await SusafeToken.new({from: alice});
    });

    it('should have correct name and symbol and decimal', async () => {
        const name = await this.susafe.name();
        const symbol = await this.susafe.symbol();
        const decimals = await this.susafe.decimals();
        assert.equal(name.valueOf(), 'SusafeToken');
        assert.equal(symbol.valueOf(), 'SUSAFE');
        assert.equal(decimals.valueOf(), '18');
    });

    it('should only allow owner to mint token', async () => {
        await this.susafe.mint(alice, '100', {from: alice});
        await this.susafe.mint(bob, '1000', {from: alice});
        await expectRevert(
            this.susafe.mint(carol, '1000', {from: bob}),
            'Ownable: caller is not the owner',
        );
        const totalSupply = await this.susafe.totalSupply();
        const aliceBal = await this.susafe.balanceOf(alice);
        const bobBal = await this.susafe.balanceOf(bob);
        const carolBal = await this.susafe.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '100');
        assert.equal(bobBal.valueOf(), '1000');
        assert.equal(carolBal.valueOf(), '0');
    });

    it('should supply token transfers properly', async () => {
        await this.susafe.mint(alice, '100', {from: alice});
        await this.susafe.mint(bob, '1000', {from: alice});
        await this.susafe.transfer(carol, '10', {from: alice});
        await this.susafe.transfer(carol, '100', {from: bob});
        const totalSupply = await this.susafe.totalSupply();
        const aliceBal = await this.susafe.balanceOf(alice);
        const bobBal = await this.susafe.balanceOf(bob);
        const carolBal = await this.susafe.balanceOf(carol);
        assert.equal(totalSupply.valueOf(), '1100');
        assert.equal(aliceBal.valueOf(), '90');
        assert.equal(bobBal.valueOf(), '900');
        assert.equal(carolBal.valueOf(), '110');
    });

    it('should fail if you try to do bad transfers', async () => {
        await this.susafe.mint(alice, '100', {from: alice});
        await expectRevert(
            this.susafe.transfer(carol, '110', {from: alice}),
            'ERC20: transfer amount exceeds balance',
        );
        await expectRevert(
            this.susafe.transfer(carol, '1', {from: bob}),
            'ERC20: transfer amount exceeds balance',
        );
    });
});
