// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyHealthLedger {
    address public owner;
    bool public isContractActive = true;

    struct EHR {
        string ipfsHash;
        uint256 timestamp;
        address hcp; 
    }

    struct HCP {
        address metamaskAddress;
        mapping(address => bool) availablePatients;
    }

    struct Patient {
        address metamaskAddress;
        mapping(address => bool) authorizedHCPs;  
        mapping(address => EHR[]) ehrs; // mapping from HCP to list of EHRs
    }

    mapping(address => HCP) public hcps;  
    mapping(address => Patient) public patients;

    mapping(address => string) public userIPFSHashes;

    address[] public hcpAddresses;  
    address[] public patientAddresses;

    event AccessGranted(address indexed patient, address indexed hcp);  
    event AccessRevoked(address indexed patient, address indexed hcp);   
    event UserProfileLinked(address indexed user, string ipfsHash);
    event HCPSignedIn(address indexed hcp);  
    event PatientSignedIn(address indexed patient);
    event PatientEHRIPFSHashStored(address indexed patient, address indexed hcp, string ipfsHash);  

    modifier onlyActiveContract() {
        require(isContractActive, "Contract is no longer active");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createHCP() public onlyActiveContract {
        if (hcps[msg.sender].metamaskAddress == address(0)) {
            hcps[msg.sender].metamaskAddress = msg.sender;
            hcpAddresses.push(msg.sender);
        }
        emit HCPSignedIn(msg.sender);  // Emit the HCPSignedIn event
    }

    function createPatient() public onlyActiveContract {
        if (patients[msg.sender].metamaskAddress == address(0)) {
            patients[msg.sender].metamaskAddress = msg.sender;
            patientAddresses.push(msg.sender);
        }
        emit PatientSignedIn(msg.sender);
    }

    function grantAccess(address hcp) external onlyActiveContract {
        require(
            patients[msg.sender].metamaskAddress != hcp,
            "Patient cannot grant access to themselves"
        );
        patients[msg.sender].authorizedHCPs[hcp] = true;  // Grant access to the HCP
        hcps[hcp].availablePatients[msg.sender] = true;

        emit AccessGranted(msg.sender, hcp);  // Emit AccessGranted event
    }

    function revokeAccess(address hcp) external onlyActiveContract {
        require(
            patients[msg.sender].authorizedHCPs[hcp],
            "Access not granted"
        );
        patients[msg.sender].authorizedHCPs[hcp] = false;  // Revoke access from the HCP
        hcps[hcp].availablePatients[msg.sender] = false;
        emit AccessRevoked(msg.sender, hcp);  // Emit AccessRevoked event
    }

    function viewAvailablePatients()
        external
        view
        onlyActiveContract
        returns (address[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < patientAddresses.length; i++) {
            if (hcps[msg.sender].availablePatients[patientAddresses[i]]) {
                count++;
            }
        }

        address[] memory availablePatients = new address[](count);
        uint256 index;
        for (uint256 i = 0; i < patientAddresses.length; i++) {
            if (hcps[msg.sender].availablePatients[patientAddresses[i]]) {
                availablePatients[index++] = patientAddresses[i];
            }
        }
        return availablePatients;
    }

    function viewAuthorizedHCPs()
        external
        view
        onlyActiveContract
        returns (address[] memory)
    {
        uint256 count;
        for (uint256 i = 0; i < hcpAddresses.length; i++) {
            if (patients[msg.sender].authorizedHCPs[hcpAddresses[i]]) {
                count++;
            }
        }

        address[] memory authorizedHCPs = new address[](count); 
        uint256 index;
        for (uint256 i = 0; i < hcpAddresses.length; i++) {
            if (patients[msg.sender].authorizedHCPs[hcpAddresses[i]]) {
                authorizedHCPs[index++] = hcpAddresses[i];
            }
        }

        return authorizedHCPs;
    }

    // Function to store the patient's EHR IPFS hash and associate it with the HCP
    function storePatientEHRIPFSHash(address patient, string memory ipfsHash)
        external
        onlyActiveContract
    {
        require(hcps[msg.sender].metamaskAddress != address(0), "HCP not found");
        require(patients[patient].authorizedHCPs[msg.sender], "Access not granted");

        // Store the EHR in the patient's record with the HCP's address
        patients[patient].ehrs[msg.sender].push(
            EHR({
                ipfsHash: ipfsHash,
                timestamp: block.timestamp,
                hcp: msg.sender  
            })
        );

        emit PatientEHRIPFSHashStored(patient, msg.sender, ipfsHash);  // Emit event for storing EHR
    }

    // Function to store the user profile's IPFS hash (e.g., for a patient or HCP profile)
    function storeUserProfileIPFSHash(string memory _hash)
        public
        onlyActiveContract
    {
        userIPFSHashes[msg.sender] = _hash;
        emit UserProfileLinked(msg.sender, _hash);
    }

    function destroyContract() public onlyActiveContract {
        require(msg.sender == owner, "Only the owner can destroy the contract");
        isContractActive = false;
    }

    function getHCPAddresses()
        public
        view
        onlyActiveContract
        returns (address[] memory)
    {
        return hcpAddresses;  // Return list of HCP addresses
    }

    function getPatientAddresses()
        public
        view
        onlyActiveContract
        returns (address[] memory)
    {
        return patientAddresses;
    }
}