# 📜 Travel Notes

This is the contract part of Travel Notes which is developed during ETHBeijing Hackathon.

Access https://github.com/LightmNFT/travel-notes to get ui.

## Structure
I'm leveraging my past work: "Lightm" which is a ERC2535 implementation of RMRK standard (composable NFT standard).

![](Travel%20Notes%20flow.png)

Part of the contract standard draws on historical achievements
This development has mainly completed the following parts:
- POAP implementation and initialization
  - Introduce ERC6454 for the simplest soul-bound implementation
  - Allows you to decide whether POAP is sbt at mint time
- Implement POAP factory contracts so that only each factory-deployed POAP can be sent to Travel Notes
- Implement Travel Notes
  - Only whitelisted addresses can send POAPs to Travel Notes
  - Mint Travel Notes automatically obtains the original Broken Parchment
- UI deployment cannot be provided due to time constraints. Therefore, you can use the deployment script to try Travel Notes locally (You can change network to do it on chain):
  1. Run `npx hardhat run ./scripts/deploy_travel_notes.ts --network localhost`
  2. Run `npx hardhat run ./scripts/deploy_poap_factory.ts --network localhost`
  3. (optional) We have `deployPOAP` and `mintPOAP` in `./scripts/deploy_poap_factory.ts` to help you deploy/mint new POAP to Travel Notes

### Contract Info

On Scroll L2:
- TravelNotes
  - address: 0x5e0E8ddef7b637641F85b9e29Fe477c4c17e633D
- POAP Factory
  - address: 0x630520ce0D19a668Ad85D20aC546000f165A82B5
- 5 Sample POAP
  - 入世(Hello World): 0xBa81Bc3604CADa30e67327015adCe505fF2aDA13
  - 奉献(Willing To Give): 0xc8b24b7D4911ab8dc98a090fd868234389d05E60
  - 忠诚(Loyalty): 0x5558533C0e781B419303B04A2992Ab8CF6AF87C6
  - 笼中鸟(Caged Bird): 0x1DCD68BC1Ea491D7520fF74D76cA6a0EacfC36ed
  - 广场大鹅(Square Goose): 0xDeca8E124df52040118C8cdE73E7A6F321F76Ba0

### Tips
The TravelNotes and POAP are both ERC2535, you could inspect them on https://louper.dev

As no UI for people to mint POAP, I've prepared a trial account, the private key is `93794b642bc0e451d67b8cb65e8b5e41a52994aa1b1eac1393f212ca3c7eb505`.
Please do not try to transfer TravelNotes!