const {expectRevert, time} = require('@openzeppelin/test-helpers');
const ethers = require('ethers');
const SusafeToken = artifacts.require('SusafeToken');
const SusafeChef = artifacts.require('SusafeChef');
const MockERC20 = artifacts.require('MockERC20');
const Timelock = artifacts.require('Timelock');

function encodeParameters(types, values) {
    const abi = new ethers.utils.AbiCoder();
    return abi.encode(types, values);
}

contract('Timelock', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.susafe = await SusafeToken.new({from: alice});
        this.timelock = await Timelock.new(bob, '21600', {from: alice});
    });

    it('should not allow non-owner to do operation', async () => {
        await this.susafe.transferOwnership(this.timelock.address, {from: alice});
        await expectRevert(
            this.susafe.transferOwnership(carol, {from: alice}),
            'Ownable: caller is not the owner',
        );
        await expectRevert(
            this.susafe.transferOwnership(carol, {from: bob}),
            'Ownable: caller is not the owner',
        );
        await expectRevert(
            this.timelock.queueTransaction(
                this.susafe.address, '0', 'transferOwnership(address)',
                encodeParameters(['address'], [carol]),
                (await time.latest()).add(time.duration.days(4)),
                {from: alice},
            ),
            'Timelock::queueTransaction: Call must come from admin.',
        );
    });

    it('should do the timelock thing', async () => {
        await this.susafe.transferOwnership(this.timelock.address, {from: alice});
        const eta = (await time.latest()).add(time.duration.days(4));
        await this.timelock.queueTransaction(
            this.susafe.address, '0', 'transferOwnership(address)',
            encodeParameters(['address'], [carol]), eta, {from: bob},
        );
        await time.increase(time.duration.days(1));
        await expectRevert(
            this.timelock.executeTransaction(
                this.susafe.address, '0', 'transferOwnership(address)',
                encodeParameters(['address'], [carol]), eta, {from: bob},
            ),
            "Timelock::executeTransaction: Transaction hasn't surpassed time lock.",
        );
        await time.increase(time.duration.days(4));
        await this.timelock.executeTransaction(
            this.susafe.address, '0', 'transferOwnership(address)',
            encodeParameters(['address'], [carol]), eta, {from: bob},
        );
        assert.equal((await this.susafe.owner()).valueOf(), carol);
    });

    it('should also work with SusafeChef', async () => {
        this.lp1 = await MockERC20.new('LPToken', 'LP', '10000000000', {from: minter});
        this.lp2 = await MockERC20.new('LPToken', 'LP', '10000000000', {from: minter});
        this.chef = await SusafeChef.new(this.susafe.address, '1000', '0', {from: alice});
        await this.susafe.transferOwnership(this.chef.address, {from: alice});
        await this.chef.add('100', this.lp1.address, true, 0);
        await this.chef.transferOwnership(this.timelock.address, {from: alice});
        const eta = (await time.latest()).add(time.duration.days(4));
        await this.timelock.queueTransaction(
            this.chef.address, '0', 'set(uint256,uint256,bool)',
            encodeParameters(['uint256', 'uint256', 'bool'], ['0', '200', false]), eta, {from: bob},
        );
        await this.timelock.queueTransaction(
            this.chef.address, '0', 'add(uint256,address,bool,uint256)',
            encodeParameters(['uint256', 'address', 'bool', 'uint256'], ['100', this.lp2.address, false, 0]), eta, {from: bob},
        );
        await time.increase(time.duration.days(4));
        await this.timelock.executeTransaction(
            this.chef.address, '0', 'set(uint256,uint256,bool)',
            encodeParameters(['uint256', 'uint256', 'bool'], ['0', '200', false]), eta, {from: bob},
        );
        await this.timelock.executeTransaction(
            this.chef.address, '0', 'add(uint256,address,bool,uint256)',
            encodeParameters(['uint256', 'address', 'bool', 'uint256'], ['100', this.lp2.address, false, 0]), eta, {from: bob},
        );
        console.log(encodeParameters(['uint256', 'address', 'bool', 'uint256'], ['3000', '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2', false, 0]));
        assert.equal((await this.chef.poolInfo('0')).valueOf().allocPoint, '200');
        assert.equal((await this.chef.totalAllocPoint()).valueOf(), '300');
        assert.equal((await this.chef.poolLength()).valueOf(), '2');
    });
});
