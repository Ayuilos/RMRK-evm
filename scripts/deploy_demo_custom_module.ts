import { ethers } from 'hardhat';
import fs from 'fs/promises';

export async function deployDemoCustomModule() {
  const signer = (await ethers.getSigners())[0];
  const DemoCustomModuleFactory = await ethers.getContractFactory('DemoCustomModule', signer);

  console.log('deploy demo custom module');

  const demoCustomModule = await DemoCustomModuleFactory.deploy();
  await demoCustomModule.deployed();

  console.log('deploy successfully');

  const filePath = './scripts/demoCustomModuleAddress.json';
  await fs.writeFile(filePath, JSON.stringify({ address: demoCustomModule.address }), {
    encoding: 'utf-8',
  });

  console.log(demoCustomModule.address);
}
