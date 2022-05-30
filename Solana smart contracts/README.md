
# Stoke NFT solana smart contract structure.

This is for our front-end engineers to understand how this contract folder interacts with our website.

PLEASE NOTE THAT YOU CAN EDIT, REPLACE OR DELETE ANYTHING YOU FIND REDUNDANT OR UNIMPORTANT IN THE JS FOLDER THAT HAS BEEN CLASSIFIED AS  FRONT-END FILES IN ORDER TO AVOID COMPATIBILITY ISSUES. MAJORITY OF THE FRONT END FILES WERE GOTTEN FROM METAPLEX STOREFRONT CREATOR AS A TEMPLATE TO SHOW YOU HOW MY SMART CONTRACTS REACT WITH A STORE FRONT(BECAUSE METAPLEX IS THE LEADING STANDARD IN SOLANA STORE FRONT CREATION).



## Solana Breakdown
This folder contains two parts,

1. An on-chain Solana smart contract coded in rust. (The program folder) is the core Solana code, and some Metaplex contracts were added for security and efficiency.



2. An off-chain code coupled with Solana web3 JS files in (The JS folder). This is where front-end integration meets the smart contracts and therefore is the subject of this readme file.
 
## CLI FOLDER
This is the back-end off-chain folder, made with Anchor that helps the JS folder communicate with the smart contracts & and the Solana network, it contains instructions & processes for minting and sales. Candy Machine CLI is the back end code for Minting and the fair-launch folder is the back end code for auctions and fixed sale listings.


## COMMON FOLDER
COMMON FOLDER
This folder contains some front-end files and the folder is the middle-man with common instructions for the entire JS folder.


1. (Contexts); This houses the instructions for connections with the rust folder, and connections with various Solana wallets(via the Solana wallet adapter).



2. (Constants); Folder contains strictly front-end files.



3. (Models); Contains further instructions including setting whitelisted creators.

 
4. (Components); This folder contains mostly front-end files like the Back button, Token display, Index, Explorer link & wallet adapter-based code.


5. (Action folder); Contains action instructions for auction(start&stop), storage of public accounts and solana rent details,vaults etc.

## FAIR LAUNCH
(THE MAIN ENV FOLDER)
(THE MAIN ENV FOLDER)

It contains,

1. .ENV file; (This contains the fair-launch(sales) & candy-machine(minting)) environment I.Ds, these are the public keys of the smart contracts). It also contains the network information and the website of Solana.


2. Public file; This contains front-end files like the favicon. 

3. SRC folder; This contains strictly front-end files made with react.

## WEB
It contains,
This folder contains mostly front-end files including,

* The ENV file, this is how the store connects to Solana, the store’s Solana public key, for the escrow service.

* The SRC folder contains the;

1. Actions; This contains the most important scripts for basic actions on the website.
2. Components; Front-end integration template.
3. Context; Code for getting the live Solana price updates from coin gecko.
4. Constants; Front-end labels & constants
5. Hooks
6. Types, views& utils 

