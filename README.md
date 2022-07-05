# Setup Etherum Development Environment

following [this](https://www.youtube.com/watch?v=SnGwaRZ1Ci0) video (bad)

and [this](https://medium.com/coinmonks/creating-and-deploying-smart-contracts-using-truffle-and-ganache-ffe927fa70ae) blog post (good)

1. Setup [Ganache](https://www.youtube.com/redirect?event=video_description&redir_token=QUFFLUhqbEhvS1FkWnR6Z0NXWlQxSlBXNWtCQmVjNGdyZ3xBQ3Jtc0tuX3IxTWhvN3ZOSHo1QU1aQ0lLQ3dyZDNzajZjTzNnSWpiWjhGX3U2cUtQVVhfaWRJb20zdzBwWTB1LUVIc2taNi11bUtmaC1nWHNRNGZ6c0cxVkxHYVZtY2xwQXZWS243c0NnTklIR19rZ0NjX2VNMA&q=https%3A%2F%2Ftrufflesuite.com%2Fganache%2F&v=SnGwaRZ1Ci0) 
    1. Download & install
    2. use `quickstart` to setup a new environment
2. In vscode: 
    1. install [solidity](https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity) extension
    2. install [css tailwind](https://marketplace.visualstudio.com/items?itemName=bradlc.vscode-tailwindcss) extension
3. create new empty repo on [github](https://github.com/diesistdername/blockprop)
4. in VSCode: clone that repo
    1. `Shift+Shift to open quick actions` 
    2. `Git Clone` - Authorize VSCode, select the new empty repo
    3. `cd` into that repo
5. in VSCode: setup environment
    1. `npm init` (use all the default settings)
    2. `npm install -g truffle`
    3. `truffle console`
    4. `truffle init`
6. connect ganache
    1. in Ganache UI - connect with ganache: 
        
        ![CleanShot 2022-06-12 at 13.17.48@2x.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/2f9a69d3-f3df-4d83-95fb-4b33baf4e6bb/CleanShot_2022-06-12_at_13.17.482x.png)
        
        1. settings>add project>(browse to `truffle-config.js`)
        2. save & restart
    2. in `truffle-config.js` - uncomment as follows (line 37) (and save the changes):
    
    ```solidity
    ...
    development: {
         host: "127.0.0.1",     // Localhost (default: none)
         port: 8545,            // Standard Ethereum port (default: none)
         network_id: "*",       // Any network (default: none)
        },
    ...
    ```
    
    1. it’s important that the ip + port match the ones in truffle (here 8545 needed to be changed to 7545, and * to 5777:
    
    ![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/24bb9741-c6ff-4b60-8aec-8dfc787be009/Untitled.png)
    
7. create own contract:
    1. `touch contracts/Storage.sol`
    2. open that file, paste this: 
    
    ```solidity
    //SPDX-License-Identifier: MIT  
    pragma solidity ^0.8.11;  
    contract Storage {      
       string public name;      
       function setName(string memory _name) public {         
          name = _name;     
       }  
    }
    ```
    
    1. `touch migrations/*2_deploy_storage.j*`
    2. open that file, paste this: 
    
    ```solidity
    const Storage = artifacts.require("Storage");  
    module.exports = function (deployer) {   
       deployer.deploy(Storage); 
    };
    ```
    
8. deploy contract
    1. `truffle console`
    2. `truffle migrate`
9. tada:

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/9710605c-68c9-479f-b093-ffd0dd37ebfc/Untitled.png)

# Known issues & fixes

1. unknown command: `truffle: command not found`

→ make sure you’ve run `npm init` at the very beginning, 

1. insuffcient funds

![Untitled](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/ed150f14-b1ac-4710-9937-478ecd90361d/Untitled.png)

![CleanShot 2022-06-12 at 14.03.56@2x.png](https://s3-us-west-2.amazonaws.com/secure.notion-static.com/f773b5c5-fadf-44c7-8e32-571d031abb71/CleanShot_2022-06-12_at_14.03.562x.png)

→ close ganache, open it again, quickstart, run `truffle migrate` again