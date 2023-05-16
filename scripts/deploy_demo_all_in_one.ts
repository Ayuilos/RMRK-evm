import { ethers } from 'hardhat';
import { Fixed, Slot, deployCatalog } from './deploy_catalog';
import { deployCollectionWithCustomModule } from './deploy_collection_with_custom_module';
import { deployDemoCustomModule } from './deploy_demo_custom_module';
import { getCatalogPartId } from './libraries/catalog';
import lightmUniversalFactoryAddress from './universalFactoryAddress.json';
import { constants } from 'ethers';

// You must run `./script/deploy_universal_factory.ts` before running this script
async function allInOne() {
  console.log('Running lightm demo all-in-one script');

  const signer = (await ethers.getSigners())[0];

  await deployDemoCustomModule();

  console.log('deploy collections');

  const bodyAddress = await deployCollectionWithCustomModule();
  const headWearAddress = await deployCollectionWithCustomModule();
  const handWearAddress = await deployCollectionWithCustomModule();

  console.log('deploy successfully');

  console.log('deploy catalog');

  const parts = [
    {
      partId: getCatalogPartId(1, 1, 0),
      part: {
        itemType: Fixed,
        z: 1,
        equippable: [],
        metadataURI:
          'ipfs://bafybeiceeipru46mxy6dq74ncafhdricria7lrzbh4a6l3l65knxh3l2f4/lightm-demo-body.json',
      },
    },
    {
      partId: getCatalogPartId(2, 1, 1),
      part: {
        itemType: Slot,
        z: 2,
        equippable: [],
        metadataURI: 'ipfs://bafkreifnwssqi5wkvclvcp224tsami4kibo6kvo2uulmub3k2cnil75ski',
      },
    },
    {
      partId: getCatalogPartId(3, 1, 1),
      part: {
        itemType: Slot,
        z: 3,
        equippable: [],
        metadataURI: 'ipfs://bafkreiejmbd7uatb5cj3gpq62smmrdzb264dmid46ojtzh2jzijdessqem',
      },
    },
  ];

  const catalogAddress = await deployCatalog({
    metadataURI: '',
    type_: 'image',
    lightmUniversalFactoryAddress: lightmUniversalFactoryAddress.address,
    parts,
  });
  console.log('deploy successfully');

  console.log('set slot permission to public');
  const catalog = await ethers.getContractAt('LightmCatalogImplementer', catalogAddress, signer);

  await catalog.setEquippableToAll(parts[1].partId);
  await catalog.setEquippableToAll(parts[2].partId);
  console.log('set successfully');

  const bodyContract = await ethers.getContractAt('LightmImpl', bodyAddress, signer);
  const headContract = await ethers.getContractAt('LightmImpl', headWearAddress, signer);
  const handContract = await ethers.getContractAt('LightmImpl', handWearAddress, signer);

  console.log('add asset entry');

  await bodyContract.addCatalogRelatedAssetEntry(
    1,
    {
      catalogAddress,
      partIds: parts.map((p) => p.partId),
      targetCatalogAddress: constants.AddressZero,
      targetSlotId: 0,
    },
    'ipfs://bafkreieroobg4h6v5nk7qa3lgcctmp6x2icecqhws37nlstnhlbdo7j25e',
  );
  await bodyContract.addAssetEntry(
    2,
    'ipfs://bafkreie4ajxmddsa2dtxyuit4cbxj2hu2ybem55nti2zsu76y4h425eohq',
  );
  await headContract.addCatalogRelatedAssetEntry(
    1,
    {
      catalogAddress: constants.AddressZero,
      partIds: [],
      targetCatalogAddress: catalogAddress,
      targetSlotId: parts[1].partId,
    },
    'ipfs://bafybeiceeipru46mxy6dq74ncafhdricria7lrzbh4a6l3l65knxh3l2f4/lightm-demo-hat.json',
  );
  await handContract.addCatalogRelatedAssetEntry(
    1,
    {
      catalogAddress: constants.AddressZero,
      partIds: [],
      targetCatalogAddress: catalogAddress,
      targetSlotId: parts[2].partId,
    },
    'ipfs://bafybeiceeipru46mxy6dq74ncafhdricria7lrzbh4a6l3l65knxh3l2f4/lightm-demo-scepter.json',
  );

  console.log('deploy successfully');

  console.log('allow public mint');

  const bodyMintModule = await ethers.getContractAt(
    'LightmMintModuleImplementer',
    bodyAddress,
    signer,
  );
  const headMintModule = await ethers.getContractAt(
    'LightmMintModuleImplementer',
    headWearAddress,
    signer,
  );
  const handMintModule = await ethers.getContractAt(
    'LightmMintModuleImplementer',
    handWearAddress,
    signer,
  );

  await bodyMintModule.setMintPermission(0, true);
  await headMintModule.setMintPermission(0, true);
  await handMintModule.setMintPermission(0, true);

  console.log('public mint allowed');

  console.log('All done');
}

allInOne();
