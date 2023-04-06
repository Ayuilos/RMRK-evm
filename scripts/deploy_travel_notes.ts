import { writeFile } from 'fs/promises';
import { ethers } from 'hardhat';
import { oneTimeDeploy, deployCreate2Deployer } from './deploy_diamond_equippable';

type PromiseResultType<P> = P extends Promise<infer R> ? R : P;

export const CREATE2_DEPLOYER_ADDRESS = '0xCf2281070e6a50E4050694EEF1a9a7376628d663';

export async function deployDiamondAndCutFacet(
  create2DeployerAddress: string,
  { diamondCutFacetAddress, cut }: PromiseResultType<ReturnType<typeof oneTimeDeploy>>,
) {
  const contractOwner = (await ethers.getSigners())[0];

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond');
  // ---------- Normal deployment
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacetAddress);
  await diamond.deployed();
  // -----------------

  // ---------- Create2 deployment
  // const create2Deployer = await ethers.getContractAt('Create2Deployer', create2DeployerAddress);
  // const diamondHash = ethers.utils.id('Diamond');
  // const diamondByteCode = ethers.utils.concat([
  //   Diamond.bytecode,
  //   ethers.utils.defaultAbiCoder.encode(
  //     ['address', 'address'],
  //     [contractOwner.address, diamondCutFacetAddress],
  //   ),
  // ]);
  // await create2Deployer.deploy(0, diamondHash, diamondByteCode);

  // const diamondAddress = await create2Deployer['computeAddress(bytes32,bytes32,byte32)'](
  //   diamondHash,
  //   ethers.utils.keccak256(diamondByteCode),
  //   deployerAddressForComputing,
  // );
  // const diamond = await ethers.getContractAt('Diamond', diamondAddress);
  // -------------------

  console.log('Diamond deployed:', diamond.address);
  try {
    const filePath = './scripts/travelNotesAddress.json';
    await writeFile(filePath, JSON.stringify({ address: diamond.address }), {
      encoding: 'utf-8',
    });

    console.log('Travel Notes address has been writing to', filePath);
  } catch (e) {
    console.log(e);
  }

  // deploy TravelNotesInit
  // TravelNotesInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const TravelNotesInit = await ethers.getContractFactory('TravelNotesInit');

  // ---------- Normal deployment
  const travelNotesInit = await TravelNotesInit.deploy();
  await travelNotesInit.deployed();

  const travelNotesInitAddress = travelNotesInit.address;
  // -----------------

  // ---------- Create2 deployment
  // const travelNotesInitHash = ethers.utils.id('TravelNotesInit');

  // const travelNotesInitByteCode = TravelNotesInit.bytecode;
  // await create2Deployer.deploy(0, travelNotesInitHash, travelNotesInitByteCode);

  // const travelNotesInitAddress = await create2Deployer['computeAddress(bytes32,bytes32,byte32)'](
  //   travelNotesInitHash,
  //   ethers.utils.keccak256(travelNotesInitByteCode),
  //   deployerAddressForComputing,
  // );
  // ------------------

  console.log('TravelNotesInit deployed:', travelNotesInitAddress);

  // upgrade diamond with facets
  console.log('');

  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address);

  // Write down your own token's name & symbol & fallbackURI & collectionMetadataURI below
  const initStruct = [['Test', 'TEST', '', ''], contractOwner.address];

  // call to init function
  const functionCall = TravelNotesInit.interface.encodeFunctionData('init', initStruct);
  const tx = await diamondCut.diamondCut(cut, travelNotesInitAddress, functionCall);
  console.log('Diamond cut tx: ', tx.hash);
  const receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  console.log('Completed diamond cut');
  return diamond.address;
}

async function deploy() {
  // If create2Deployer is already deployed, comment this line.
  const CREATE2_DEPLOYER_ADDRESS = await deployCreate2Deployer();

  // - If these one-time deployment contracts in this function have been deployed,
  // you should set the 2nd param to `true` to avoid deploying and take the return value for invoking `deployDiamondAndCutFacet`.
  // - If wanna take the `cut` for using in `RMRKUniversalFactory` to make deployment process totally happen on chain,
  // set 2nd param to `true`, set 3rd param to the address of `RMRKUniversalFactory` to make sure the address is computed correctly.
  const returnValue = await oneTimeDeploy(CREATE2_DEPLOYER_ADDRESS, false, true, {
    override: {
      useNormalDeploy: { TravelNotes: true },
      FacetNames: [
        'DiamondLoupeFacet',
        'LightmEquippableMultiAssetFacet',
        'LightmEquippableNestableFacet',
        'LightmEquippableFacet',
        'RMRKCollectionMetadataFacet',
        'TravelNotes',
        'LightmImpl',
      ],
    },
    addOn: {
      toBeRemovedFunctions: { LightmEquippableNestableFacet: ['addChild(uint256,uint256,bytes)'] },
    },
  });

  return await deployDiamondAndCutFacet(CREATE2_DEPLOYER_ADDRESS, returnValue);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deploy()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
