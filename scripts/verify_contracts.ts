import hre from 'hardhat';

const Create2DeployerAddr = '0x193F37A630B1380F92D2Aea5177Aa5C5b6BF7D1F';
const RMRKValidatorLibAddr = '0x578Dcfff22a463d50dD03AB7c269E6544e2f5419';
const DiamondCutFacetAddr = '0x6c21ED39c85492E73CcBe4f354A0B765a8971f45';
const DiamondLoupeFacetAddr = '0xb7bAb9639FA88702081406627417febd34973db7';
const RMRKEquippableMultiResourceFacetAddr = '0xffBA44B1dA0145F2Eae7498461082923352E3608';
const RMRKEquippableNestingFacetAddr = '0x327384513662d4EFb7bdd522b88768D845BA956c';
const DiamondAddr = '0x5C228E2EaccA53f705f483Fd6878F6724cF44486';
const EquippableInitAddr = '0x481f1f71581F8219735c15b53D95237Ec9Cc18b7';
const RMRKEquippableImplAddr = '0x31175A579847DEe105DF2d751950010EcE0FF911';

// It's a IIFE
(async function () {
  const toBeVerifiedArr = [
    // Create2Deployer
    {
      address: Create2DeployerAddr,
    },
    // RMRKValidatorLib 0.1.0
    {
      address: RMRKValidatorLibAddr,
    },
    // DiamondCutFacet
    {
      address: DiamondCutFacetAddr,
    },
    // DiamondLoupeFacet
    {
      address: DiamondLoupeFacetAddr,
    },
    // RMRKEquippableMultiResourceFacet 0.1.0-alpha
    {
      address: RMRKEquippableMultiResourceFacetAddr,
      libraries: {
        RMRKValidatorLib: RMRKValidatorLibAddr,
      },
    },
    // RMRKEquippableNestingFacet 0.1.0-alpha
    {
      address: RMRKEquippableNestingFacetAddr,
      constructorArguments: ['RMRKEquippableNesting-0.1.0-alpha', 'RMRKEN-0.1.0-alpha'],
    },
    // Diamond & EquippableInit. NOTE that they're deployed by your account, MODIFY the corresponding variable.
    {
      address: DiamondAddr,
      constructorArguments: ['0xFBa50dD46Af71D60721C6E38F40Bce4d2416A34B', DiamondCutFacetAddr],
    },
    {
      address: EquippableInitAddr,
    },
    {
      address: RMRKEquippableImplAddr,
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