import { writeFile } from 'fs/promises';
import { ethers } from 'hardhat';
import { LightmInit__factory } from '../typechain-types';
import { ILightmUniversalFactory } from '../typechain-types/contracts/src/LightmUniversalFactory';
import {
  create2DeployerAddress,
  deployCreate2Deployer,
  oneTimeDeploy,
  version,
} from './deploy_diamond_equippable';

export default async function deployUniversalFactory(
  create2DeployerAddress: string,
  constructParams: ILightmUniversalFactory.ConstructParamsStruct,
) {
  const signers = await ethers.getSigners();
  const create2Deployer = await ethers.getContractAt('Create2Deployer', create2DeployerAddress);
  const UniversalFactory = await ethers.getContractFactory('LightmUniversalFactory', signers[0]);

  const hash = ethers.utils.id(`LightmUniversalFactory${version}`);

  const constructorParams = ethers.utils.defaultAbiCoder.encode(
    [
      'tuple(address validatorLibAddress,address maRenderUtilsAddress,address equippableRenderUtilsAddress,address diamondCutFacetAddress,address diamondLoupeFacetAddress,address nestableFacetAddress,address multiAssetFacetAddress,address equippableFacetAddress,address rmrkEquippableFacetAddress,address collectionMetadataFacetAddress,address initContractAddress,address implContractAddress,address mintModuleAddress,tuple cuts(address facetAddress,uint8 action,bytes4[] functionSelectors)[])',
    ],
    [constructParams],
  );

  const bytecode = ethers.utils.concat([UniversalFactory.bytecode, constructorParams]);

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

  const create2DeployerAddress = await deployCreate2Deployer();
  const create2Deployer = await ethers.getContractAt(
    'Create2Deployer',
    create2DeployerAddress,
    signers[0],
  );

  const lightmInitHash = ethers.utils.id(`LightmInit-${version}`);
  let tx = await create2Deployer.deploy(0, lightmInitHash, LightmInit__factory.bytecode);
  await tx.wait();

  const lightmInitAddress = await create2Deployer['computeAddress(bytes32,bytes32)'](
    lightmInitHash,
    ethers.utils.keccak256(LightmInit__factory.bytecode),
  );

  console.log(`LightmInit deployed: ${lightmInitAddress}`);

  let counters = 0;

  const { cut, ...rest } = await oneTimeDeploy(create2DeployerAddress, false, true);
  try {
    const filePath = './scripts/cutsForVerifyConstructors.json';
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

  const factoryAddress = await deployUniversalFactory(create2DeployerAddress, {
    validatorLibAddress: rest.lightmValidatorLibAddress,
    maRenderUtilsAddress: rest.rmrkMultiAssetRenderUtilsAddress,
    equippableRenderUtilsAddress: rest.lightmEquippableRenderUtilsAddress,
    diamondCutFacetAddress: rest.diamondCutFacetAddress,
    diamondLoupeFacetAddress: cut[0].facetAddress,
    multiAssetFacetAddress: cut[1].facetAddress,
    nestableFacetAddress: cut[2].facetAddress,
    equippableFacetAddress: cut[3].facetAddress,
    rmrkEquippableFacetAddress: cut[4].facetAddress,
    implContractAddress: cut[5].facetAddress,
    collectionMetadataFacetAddress: cut[6].facetAddress,
    mintModuleAddress: cut[7].facetAddress,
    initContractAddress: lightmInitAddress,
    cuts: cut,
  });
  console.log(`UniversalFactory Address: ${factoryAddress} with ${counters} function selectors`);

  const universalFactory = await ethers.getContractAt('LightmUniversalFactory', factoryAddress);
  tx = await universalFactory.deployCollection({
    name: 'Test',
    symbol: 'TEST',
    fallbackURI: '',
    collectionMetadataURI: '',
    mintConfig: {
      whitelistMintPrice: ethers.utils.parseEther('0.1'),
      publicMintPrice: ethers.utils.parseEther('0.15'),
      whitelistMintLimit: 1,
      publicMintLimit: 2,
      // 0 -> linear, 1 -> assignable
      mintStyle: 1,
      maxSupply: 0,
    },
  });
  const txRec = await tx.wait();
  const { events } = txRec;
  const createdEvent = events?.find(
    (eventRecord) => eventRecord.event === 'LightmCollectionCreated',
  );
  console.log(`Deploy collection: ${createdEvent?.args?.[0]}`);
  console.log('Deployment success');
}

deploy();
