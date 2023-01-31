import hre from 'hardhat';
import { ILightmUniversalFactory } from '../typechain-types/contracts/src/LightmUniversalFactory';
import cuts from './cutsForVerifyConstructors.json';

const Create2DeployerAddr = '0x193F37A630B1380F92D2Aea5177Aa5C5b6BF7D1F';
const LightmValidatorLibAddr = '0xa7C31a8Bb459356E2409026099390FCF80563dAf';
const RMRKMultiAssetRenderUtilsAddr = '0xE109Ed05ddB108b5fbe4976639867f6451173D33';
const LightmEquippableRenderUtilsAddr = '0x9E70FBD21e178dde56B2ea45d74F0b094e8fFC65';
const DiamondCutFacetAddr = '0x3A323d37Ecb7d52c1b09F3A6420658cAc15d5280';
const DiamondLoupeFacetAddr = '0x841B01fAa87407CA11930c8214f571c5c8315017';
const LightmEquippableMultiAssetFacetAddr = '0x9e57Fc10c2bD9fE00bd0369d463528A5CB7774D4';
const LightmEquippableNestableFacetAddr = '0xF446B19b10625FFFd5f0Abc3666eF09c76AB373e';
const LightmEquippableFacetAddr = '0xEF1De563b779e2d0aFCD01DD8b17629898D7cF5a';
const RMRKCollectionMetadataFacetAddr = '0xCaC876F41902A4Ee6947179f964EB3a99794EA50';
const LightmMintModuleImplementerAddr = '0xc6a4541a97985340886ce9c6166345C0dA11d24a';
const LightmImplAddr = '0x49e733CF6Ef65901511eb8c2Ad5A9FDeE4fB5F73';
const DiamondAddr = '0x28c7b9e91d33Eac2478f8e49274A9f86364ba524';
const LightmInitAddr = '0xCa35664430E26E1Ea6D0476E47602BeA8B93c667';
const LightmUniversalFactoryAddr = '0x1A2E0E5db589f44bDA45a7E8e38054a65b0eb946';

const lightmUniversalFactoryParam: ILightmUniversalFactory.ConstructParamsStruct = {
  validatorLibAddress: LightmValidatorLibAddr,
  maRenderUtilsAddress: RMRKMultiAssetRenderUtilsAddr,
  equippableRenderUtilsAddress: LightmEquippableRenderUtilsAddr,
  diamondCutFacetAddress: DiamondCutFacetAddr,
  diamondLoupeFacetAddress: DiamondLoupeFacetAddr,
  nestableFacetAddress: LightmEquippableNestableFacetAddr,
  multiAssetFacetAddress: LightmEquippableMultiAssetFacetAddr,
  equippableFacetAddress: LightmEquippableFacetAddr,
  collectionMetadataFacetAddress: RMRKCollectionMetadataFacetAddr,
  initContractAddress: LightmInitAddr,
  implContractAddress: LightmImplAddr,
  mintModuleAddress: LightmMintModuleImplementerAddr,
  cuts,
};

// It's a IIFE
(async function () {
  const toBeVerifiedArr = [
    // Create2Deployer
    {
      address: Create2DeployerAddr,
    },
    // LightmValidatorLib 0.1.0
    {
      address: LightmValidatorLibAddr,
    },
    // RMRKMultiAssetRenderUtils
    {
      address: RMRKMultiAssetRenderUtilsAddr,
    },
    // LightmEquippableRenderUtils
    {
      address: LightmEquippableRenderUtilsAddr,
    },
    // DiamondCutFacet
    {
      address: DiamondCutFacetAddr,
    },
    // DiamondLoupeFacet
    {
      address: DiamondLoupeFacetAddr,
    },
    // LightmEquippableMultiAssetFacet 0.1.0-alpha
    {
      address: LightmEquippableMultiAssetFacetAddr,
      libraries: {
        RMRKMultiAssetRenderUtils: RMRKMultiAssetRenderUtilsAddr,
      },
    },
    // LightmEquippableNestableFacet 0.1.0-alpha
    {
      address: LightmEquippableNestableFacetAddr,
      constructorArguments: ['LightmNestable-0.1.0-alpha', 'LN-0.1.0-alpha'],
      libraries: {
        RMRKMultiAssetRenderUtils: RMRKMultiAssetRenderUtilsAddr,
      },
    },
    // LightmEquippableFacet
    {
      address: LightmEquippableFacetAddr,
      constructorArguments: ['LightmMultiAsset-0.1.0-alpha', 'LMR-0.1.0-alpha'],
      libraries: {
        LightmValidatorLib: LightmValidatorLibAddr,
      },
    },
    // RMRKCollectionMetadataFacet
    {
      address: RMRKCollectionMetadataFacetAddr,
    },
    // LightmMintModuleImplementer
    {
      address: LightmMintModuleImplementerAddr,
    },
    // LightmImpl
    {
      address: LightmImplAddr,
    },
    // LightmUniversalFactory
    {
      address: LightmUniversalFactoryAddr,
      constructorArguments: [lightmUniversalFactoryParam],
    },
    // Diamond & LightmInit. NOTE that they're deployed by your account, MODIFY the corresponding variable.
    {
      address: DiamondAddr,
      constructorArguments: ['0xFBa50dD46Af71D60721C6E38F40Bce4d2416A34B', DiamondCutFacetAddr],
    },
    {
      address: LightmInitAddr,
    },
  ];

  for (let i = 0; i < toBeVerifiedArr.length; i++) {
    try {
      await hre.run('verify:verify', toBeVerifiedArr[i]);
    } catch (e) {
      console.log(toBeVerifiedArr[i].address, e);
    }
  }
})();
