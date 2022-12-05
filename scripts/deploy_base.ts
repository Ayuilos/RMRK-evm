import { ethers } from 'hardhat';
import { IRMRKBaseStorage } from '../typechain-types/contracts/implementations/RMRKBaseImplementer.sol/RMRKBaseStorageImpl';

const Slot = 1;
const Fixed = 2;

export async function deployBase() {
  const signer = (await ethers.getSigners())[0];

  const BaseFactory = await ethers.getContractFactory('RMRKBaseStorageImpl', signer);

  const base = await BaseFactory.deploy('Test', 'Test');
  await base.deployed();

  console.log('Deploy base successfully, address is', base.address);

  const part0: IRMRKBaseStorage.IntakeStructStruct = {
    partId: 1,
    part: {
      itemType: Fixed,
      z: 1,
      equippable: [],
      metadataURI: 'ipfs://bafkreifpjb6ezuidaln2vz63ma4cxedewjhu73omepcd4asv35nuzv7blq',
    },
  };

  const part1: IRMRKBaseStorage.IntakeStructStruct = {
    partId: 2,
    part: {
      itemType: Slot,
      z: 1,
      equippable: [],
      metadataURI: '',
    },
  };

  const part2: IRMRKBaseStorage.IntakeStructStruct = {
    partId: 3,
    part: {
      itemType: Slot,
      z: 1,
      equippable: [],
      metadataURI: '',
    },
  };

  let tx = await base.addPartList([part0, part1, part2]);
  await tx.wait();

  tx = await base.setEquippableToAll(2);
  await tx.wait();

  tx = await base.setEquippableToAll(3);
  await tx.wait();

  return base.address;
}

deployBase();
