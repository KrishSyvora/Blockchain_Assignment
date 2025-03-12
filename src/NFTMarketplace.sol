// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTMarketplace is Ownable {
    constructor() Ownable(msg.sender) {}
    struct Sale{
        address seller;
        address contractAddress;
        uint256 tokenId;
        uint256 quantity;
        uint256 price;
        address paymentToken;
        bool isERC1155;
        bool isActive;
    }
    mapping (uint256 => Sale) sales;
    uint256 private saleId;
    uint public marketplaceFee;

    function createSale(
        address contractAddress,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        address paymentToken,
        bool isERC1155
    ) external {
        require(price>0,"The price should be greater than 0");
        if(isERC1155){
            require(quantity>0, "Quantity must be greater than 0");
            require(IERC1155(contractAddress).balanceOf(msg.sender,tokenId)>=quantity,"Insuffiecient balance");//it'll check the no. of tokens msg.sender has of this tokenID is atleast equal to the quantity that he specified 
        }else{
            require(IERC721(contractAddress).ownerOf(tokenId)==msg.sender,"You're not the owner of this nft");
            require(quantity==1,"Quantity must be 1 for an ERC721");
        }

        saleId += 1;
        sales[saleId] = Sale({
            seller: msg.sender,
            contractAddress: contractAddress,
            tokenId: tokenId,
            quantity: quantity,
            price: price,
            paymentToken: paymentToken,
            isERC1155: isERC1155,
            isActive: true
        });
    }
    function buy(uint256 saleID)external payable{
        Sale storage sale = sales[saleID];//we must define data for unused local variables
        uint256 fee = (sale.price*marketplaceFee)/100;
        uint256 sellerAmount = sale.price-fee;

        if(sale.paymentToken == address(0)){//no token paid so we'll take eth 
            require(msg.value >= sale.price,"Incorrect ETH amount");
            payable(sale.seller).transfer(sellerAmount);
        }else{
            IERC20(sale.paymentToken).transferFrom(msg.sender,sale.seller,sellerAmount);
        }

        if(sale.isERC1155){
            IERC1155(sale.contractAddress).safeTransferFrom(sale.seller,msg.sender,sale.tokenId,sale.quantity,"");
        }else{
            IERC721(sale.contractAddress).safeTransferFrom(sale.seller,msg.sender,sale.tokenId);
        }

        sale.isActive = false;
        marketplaceFee += fee;
    }

    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes32) {
        revert("Your contract can't handle NFT's");
    }

    function onERC1155Received(address, address, uint256, uint256, bytes memory) public pure returns (bytes32) {//ensuring onReceived(operator,from,id,value,data) function is there or not
        revert("Your contract can't handle NFT's");
    }
    
}
