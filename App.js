import React, { useState, useEffect } from "react";
import Web3 from "web3";
import contractABI from "./contractABI.json"; // Import the ABI file generated from the smart contract

const CONTRACT_ADDRESS = process.env.REACT_APP_CONTRACT_ADDRESS;

function App() {
  const [web3, setWeb3] = useState(null);
  const [account, setAccount] = useState(null);
  const [contract, setContract] = useState(null);

  useEffect(() => {
    const initWeb3 = async () => {
      if (window.ethereum) {
        try {
          const web3Instance = new Web3(window.ethereum);
          setWeb3(web3Instance);

          
          await window.ethereum.request({ method: 'eth_requestAccounts' });

          
          const accounts = await web3Instance.eth.getAccounts();
          setAccount(accounts[0]);

          
          const contractInstance = new web3Instance.eth.Contract(contractABI, CONTRACT_ADDRESS);
          setContract(contractInstance);
        } catch (error) {
          console.error("Error initializing web3", error);
        }
      } else {
        console.error("Please install MetaMask!");
      }
    };

    initWeb3();
  }, []);

 

  return (
    <div className="App">
      <h1>Social Media DApp</h1>
      {}
    </div>
  );
}

export default App;
