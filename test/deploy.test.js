const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("PhotoRegistry Deployment", function () {
  it("Should deploy the PhotoRegistry contract", async function () {
    // コントラクトのファクトリを作成
    const PhotoRegistry = await ethers.getContractFactory("PhotoRegistry");
    
    // コントラクトをデプロイ
    const photoRegistry = await PhotoRegistry.deploy();
    
    // デプロイ完了を待機
    await photoRegistry.deploymentTransaction();
    
    // コントラクトのアドレスが存在することを確認
    const contractAddress = await photoRegistry.getAddress();
    expect(contractAddress).to.be.a('string');
    expect(contractAddress).to.not.equal('');
    
    console.log("PhotoRegistry deployed to:", contractAddress);
  });
});