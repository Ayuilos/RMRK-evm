# Lightm

Lightm is a [RMRK EVM](https://github.com/rmrk-team/evm) fork, and it uses the [EIP-2535](https://eips.ethereum.org/EIPS/eip-2535)'s [diamond 2](https://github.com/mudgen/diamond-2-hardhat) implementation to implement [RMRK Spec](https://github.com/rmrk-team/rmrk-spec/tree/master/standards/abstract).

## Note
To be added.

## Local Development
- Run `npm i` or `yarn` to install deps first.
- Run `npx hardhat node` to start a local hardhat node.
- Follow [Deployment](#deployment)

## Deployment

We use `Create2Deployer` to make sure the "to be deployed" contract addresses is predictable and so we could replay a tx on different chains and get same addresses on them. If you have some custom logics, it's totally **optional**.

Use `npx hardhat run --network localhost ./scripts/[script-name].ts` to run scripts below. If you don't specify network, it will run on Ethereum. For more infos please go to [hardhat site](https://hardhat.org/hardhat-runner/docs/getting-started).

### Full-automatic on-chain deployment

The `Full-automatic on-chain deployment` is a more appropriate approach for creators whom cannot write code. Contracts containing the same implementation code on different chains should be deployed only once. 

**Before you invoke the script below in a non-local development environment, make sure that no contract has been deployed on this chain(Check if `Create2Deployer` is deployed on target chain, its address is `0xcf2281070e6a50e4050694eef1a9a7376628d663`), otherwise this is a redundant action (except you wanna deploy your own custom factory)**.

Run [./scripts/deploy_universal_factory.ts](./scripts/deploy_universal_factory.ts) to deploy universal factory and make NFT deployment happening tolly on chain.

### Semi-automatic deployment

Run [./scripts/deploy_diamond_equippable.ts](./scripts/deploy_diamond_equippable.ts) to deploy your own custom NFT.

| Contract                                                                                   | Description                                                         | Can reuse |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------- | --------- |
| [Create2Deployer](./contracts/src/Create2Deployer.sol)                                    | A create2 contract deployer                                         | yes       |
| [DiamondCutFacet](./contracts/src/DiamondCutFacet.sol)                                    | The diamond raw facet used to add/remove/replace facet of diamond   | yes       |
| [DiamondLoupeFacet](./contracts/src/DiamondLoupeFacet.sol)                                | The diamond raw facet used to explore facets of diamond             | yes       |
| [LightmEquippableNestableFacet](./contracts/src/LightmEquippableNestableFacet.sol)        | The nestable part of equipment function supported facet             | yes       |
| [LightmEquippableMultiAssetFacet](./contracts/src/LightmEquippableMultiAssetFacet.sol)    | The multi-asset part of equipment function supported facet          | yes       |
| [LightmEquippableFacet](./contracts/src/LightmEquippableFacet.sol)                        | The equippable part of equipment function supported facet           | yes       |
| [RMRKCollectionMetadataFacet](./contracts/src/RMRKCollectionMetadataFacet.sol)            | The collection-metadata part of RMRK NFT                            | yes       |
| [Diamond](./contracts/src/Diamond.sol)                                                    | The real contract that store all state                              | no        |
| [LightmInit](./contracts/src/LightmInit.sol)                                              | The diamond raw facet used to initializes the state of the contract | yes       |
| [LightmImplementer](./contracts/implementations/LightmImplementer.sol)                     | The implementation used by `UniversalFactory` by default            | yes       |
| [LightmMintModuleImplementer](./contracts/implementations/LightmMintModuleImplementer.sol) | The isolated mint module, be used by `UniversalFactory` by default  | yes       |

#### More about mint module
- You could choose how to mint token:
  - linear (for example: from 1 -> 9999, can not specify an id)
  - assignable (can specify an id)
- Support "whitelist" by default, which is implemented by merkle tree proof:
  - public mint
    - easily start or stop minting at any time
    - set mint limit **only when deploying**
    - set mint price **only when deploying**
  - whitelist mint
    - same with public mint...
    - target address assignable (due to the implementation of whitelist, if you're willing, you could pay for your whitelist friend)