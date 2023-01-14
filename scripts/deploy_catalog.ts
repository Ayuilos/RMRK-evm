import { ethers } from 'hardhat';
import { IRMRKCatalog } from '../typechain-types/contracts/implementations/RMRKCatalogImplementer';

const Slot = 1;
const Fixed = 2;

export async function deployCatalog() {
  const signer = (await ethers.getSigners())[0];

  const CatalogFactory = await ethers.getContractFactory('RMRKCatalogImplementer', signer);

  const catalog = await CatalogFactory.deploy('Test', 'Test');
  await catalog.deployed();

  console.log('Deploy catalog successfully, address is', catalog.address);

  const part0: IRMRKCatalog.IntakeStructStruct = {
    partId: 1,
    part: {
      itemType: Fixed,
      z: 1,
      equippable: [],
      metadataURI: 'ipfs://bafkreifpjb6ezuidaln2vz63ma4cxedewjhu73omepcd4asv35nuzv7blq',
    },
  };

  const part1: IRMRKCatalog.IntakeStructStruct = {
    partId: 2,
    part: {
      itemType: Slot,
      z: 1,
      equippable: [],
      metadataURI: 'ipfs://bafkreihfdwwxn6ugoswbp7or34ue4nyziqw6smb755l2xqsvsisxhorih4',
    },
  };

  const part2: IRMRKCatalog.IntakeStructStruct = {
    partId: 3,
    part: {
      itemType: Slot,
      z: 1,
      equippable: [],
      metadataURI: 'ipfs://bafkreidaahujz2pjf6xzpcpctrms6gjxtrbomdz7oce7rdtyafrxm7uawi',
    },
  };

  let tx = await catalog.addPartList([part0, part1, part2]);
  await tx.wait();

  tx = await catalog.setEquippableToAll(2);
  await tx.wait();

  tx = await catalog.setEquippableToAll(3);
  await tx.wait();

  return catalog.address;
}

deployCatalog();
