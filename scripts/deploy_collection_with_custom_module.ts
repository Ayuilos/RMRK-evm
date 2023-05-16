import { ethers } from 'hardhat';
import demoCustomModuleAddress from './demoCustomModuleAddress.json';
import universalFactoryAddress from './universalFactoryAddress.json';
import { DemoCustomModule__factory, IDiamondCut } from '../typechain-types';

export async function deployCollectionWithCustomModule() {
  const signer = (await ethers.getSigners())[0];
  const moduleInterface = DemoCustomModule__factory.createInterface();
  const factory = await ethers.getContractAt(
    'LightmUniversalFactory',
    universalFactoryAddress.address,
    signer,
  );

  const cuts: IDiamondCut.FacetCutStruct[] = [
    {
      facetAddress: demoCustomModuleAddress.address,
      action: 0,
      functionSelectors: Object.values(moduleInterface.functions).map((fragment) =>
        moduleInterface.getSighash(fragment),
      ),
    },
  ];

  const tx = await factory.deployCollection(
    {
      name: 'Demo',
      symbol: 'DEMO',
      fallbackURI: '',
      collectionMetadataURI: '',
      royaltyNumerator: 350,
      mintConfig: {
        whitelistMintPrice: ethers.utils.parseEther('0.1'),
        publicMintPrice: ethers.utils.parseEther('0'),
        whitelistMintLimit: 1,
        publicMintLimit: 1,
        // 0 -> linear, 1 -> assignable
        mintStyle: 0,
        maxSupply: 0,
      },
    },
    cuts,
  );
  const txRec = await tx.wait();
  const { events } = txRec;
  const createdEvent = events?.find(
    (eventRecord) => eventRecord.event === 'LightmCollectionCreated',
  );
  console.log(`Deploy collection with custom module: ${createdEvent?.args?.[0]} successfully`);

  return createdEvent?.args?.[0];
}
