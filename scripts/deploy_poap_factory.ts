import { writeFile } from 'fs/promises';
import { ethers } from 'hardhat';
import { POAPInit__factory } from '../typechain-types';
import { IPOAPFactory } from '../typechain-types/contracts/travel-notes-implementations/POAPFactory.sol/POAPFactory';
import { oneTimeDeploy, version } from './deploy_diamond_equippable';
import { CREATE2_DEPLOYER_ADDRESS } from './deploy_travel_notes';

// !!! Run deploy_travel_notes.ts first to get this json
import travelNotesAddressJson from './travelNotesAddress.json';

const POAP_FACTORY_VERSION = '0.1.0';

export default async function deployPOAPFactory(
  CREATE2_DEPLOYER_ADDRESS: string,
  constructParams: IPOAPFactory.ConstructParamsStruct,
) {
  const signers = await ethers.getSigners();
  const create2Deployer = await ethers.getContractAt('Create2Deployer', CREATE2_DEPLOYER_ADDRESS);
  const POAPFactory = await ethers.getContractFactory('POAPFactory', signers[0]);

  const hash = ethers.utils.id(`POAPFactory-${POAP_FACTORY_VERSION}`);

  const constructorParams = ethers.utils.defaultAbiCoder.encode(
    [
      'tuple(address diamondCutFacetAddress,address diamondLoupeFacetAddress,address nestableFacetAddress,address multiAssetFacetAddress,address equippableFacetAddress,address collectionMetadataFacetAddress,address initContractAddress,address implContractAddress,address poapMintModuleAddress,address travelNotesAddress,tuple cuts(address facetAddress,uint8 action,bytes4[] functionSelectors)[])',
    ],
    [constructParams],
  );

  const bytecode = ethers.utils.concat([POAPFactory.bytecode, constructorParams]);

  const tx = await create2Deployer.deploy(0, hash, bytecode);
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Factory deployment failed: ${tx.hash}`);
  }

  return await create2Deployer['computeAddress(bytes32,bytes32)'](
    hash,
    ethers.utils.keccak256(bytecode),
  );
}

async function deploy() {
  const signers = await ethers.getSigners();

  const create2Deployer = await ethers.getContractAt(
    'Create2Deployer',
    CREATE2_DEPLOYER_ADDRESS,
    signers[0],
  );

  const poapInitHash = ethers.utils.id(`POAPInit-${version}`);
  let tx = await create2Deployer.deploy(0, poapInitHash, POAPInit__factory.bytecode);
  await tx.wait();

  const poapInitAddress = await create2Deployer['computeAddress(bytes32,bytes32)'](
    poapInitHash,
    ethers.utils.keccak256(POAPInit__factory.bytecode),
  );

  console.log(`POAPInit deployed: ${poapInitAddress}`);

  let counters = 0;

  const { cut, ...rest } = await oneTimeDeploy(CREATE2_DEPLOYER_ADDRESS, true, false, {
    override: {
      FacetNames: [
        'DiamondLoupeFacet',
        'LightmEquippableMultiAssetFacet',
        'LightmEquippableNestableFacet',
        'LightmEquippableFacet',
        'RMRKCollectionMetadataFacet',
        'POAP',
        'LightmImpl',
      ],
      useNormalDeploy: {
        POAP: true,
      },
    },
  });

  try {
    const filePath = './scripts/poapFactoryCutsForVerifyConstructors.json';
    await writeFile(filePath, JSON.stringify(cut), {
      encoding: 'utf-8',
    });

    console.log('Cuts has been writing to', filePath);
  } catch (e) {
    console.log(e);
  }

  for (let i = 0; i < cut.length; i++) {
    const { functionSelectors } = cut[i];

    counters += functionSelectors.length;
  }

  const travelNotesAddress = travelNotesAddressJson.address;

  const factoryAddress = await deployPOAPFactory(CREATE2_DEPLOYER_ADDRESS, {
    diamondCutFacetAddress: rest.diamondCutFacetAddress,
    diamondLoupeFacetAddress: cut[0].facetAddress,
    multiAssetFacetAddress: cut[1].facetAddress,
    nestableFacetAddress: cut[2].facetAddress,
    equippableFacetAddress: cut[3].facetAddress,
    collectionMetadataFacetAddress: cut[4].facetAddress,
    poapMintModuleAddress: cut[5].facetAddress,
    implContractAddress: cut[6].facetAddress,
    initContractAddress: poapInitAddress,
    travelNotesAddress,
    cuts: cut,
  });
  console.log(`POAPFactory Address: ${factoryAddress} with ${counters} function selectors`);

  const travelNotesImplFacet = await ethers.getContractAt(
    'LightmImpl',
    travelNotesAddress,
    signers[0],
  );
  const travelNotes = await ethers.getContractAt('TravelNotes', travelNotesAddress);
  const WL_MANAGER_ROLE = await travelNotes.WHITELIST_MANAGER_ROLE();
  tx = await travelNotesImplFacet.grantRole(WL_MANAGER_ROLE, factoryAddress);

  await tx.wait();
  console.log(`Grant WHITELIST_MANAGER_ROLE to POAP factory address: ${factoryAddress}`);

  const poapFactory = await ethers.getContractAt('POAPFactory', factoryAddress);
  tx = await poapFactory.deployPOAP({
    name: 'Test',
    symbol: 'TEST',
    fallbackURI: '',
    collectionMetadataURI: '',
  });
  const txRec = await tx.wait();
  const { events } = txRec;
  const createdEvent = events?.find((eventRecord) => eventRecord.event === 'POAPCreated');
  console.log(`Deploy POAP diamond: ${createdEvent?.args?.[0]}`);
  console.log('Deployment success');
}

deploy();
