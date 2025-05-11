// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyHealthLedger {
    address public owner;
    bool public isContractActive = true; // Flag to track the contract's active status

    struct EHR {
        string ipfsHash;
        uint256 timestamp;
        address practitioner;
    }

    struct Doctor {
        address metamaskAddress;
        mapping(address => bool) availablePatients;
    }

    struct Patient {
        address metamaskAddress;
        mapping(address => bool) authorizedDoctors;
        mapping(address => EHR[]) ehrs;
    }

    mapping(address => Doctor) public doctors;
    mapping(address => Patient) public patients;
    mapping(address => string) public userIPFSHashes;
    mapping(address => string) public patientEHRIPFSHashes;
    mapping(address => address) public ehrPractitioners;

    address[] public doctorAddresses;
    address[] public patientAddresses;

    event AccessGranted(address indexed patient, address indexed doctor);
    event AccessRevoked(address indexed patient, address indexed doctor);
    event UserProfileLinked(address indexed user, string ipfsHash);
    event DoctorSignedIn(address indexed doctor);
    event PatientSignedIn(address indexed patient);

    modifier onlyActiveContract() {
        require(isContractActive, "Contract is no longer active");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createDoctor() public onlyActiveContract {
        // Check if the doctor already exists
        if (doctors[msg.sender].metamaskAddress == address(0)) {
            // If the doctor does not exist, create a new doctor
            doctors[msg.sender].metamaskAddress = msg.sender;
            doctorAddresses.push(msg.sender);
        }
        emit DoctorSignedIn(msg.sender);
    }

    function createPatient() public onlyActiveContract {
        // Check if the patient already exists
        if (patients[msg.sender].metamaskAddress == address(0)) {
            // If the patient does not exist, create a new patient
            patients[msg.sender].metamaskAddress = msg.sender;
            patientAddresses.push(msg.sender);
        }
        emit PatientSignedIn(msg.sender);
    }

    function grantAccess(address doctor) external onlyActiveContract {
        require(
            patients[msg.sender].metamaskAddress != doctor,
            "Patient cannot grant access to themselves"
        );
        patients[msg.sender].authorizedDoctors[doctor] = true;
        doctors[doctor].availablePatients[msg.sender] = true;

        emit AccessGranted(msg.sender, doctor);
    }

    function revokeAccess(address doctor) external onlyActiveContract {
        require(
            patients[msg.sender].authorizedDoctors[doctor],
            "Access not granted"
        );
        patients[msg.sender].authorizedDoctors[doctor] = false;
        doctors[doctor].availablePatients[msg.sender] = false;
        emit AccessRevoked(msg.sender, doctor);
    }

    function viewAvailablePatients()
        external
        view
        onlyActiveContract
        returns (address[] memory)
    {
        address[] memory availablePatients;
        uint256 count = 0;
        for (uint256 i = 0; i < patientAddresses.length; i++) {
            if (doctors[msg.sender].availablePatients[patientAddresses[i]]) {
                availablePatients[count] = patientAddresses[i];
                count++;
            }
        }
        return availablePatients;
    }

    function viewAuthorizedDoctors()
        external
        view
        onlyActiveContract
        returns (address[] memory)
    {
        uint256 count = 0;
        for (uint256 i = 0; i < doctorAddresses.length; i++) {
            if (patients[msg.sender].authorizedDoctors[doctorAddresses[i]]) {
                count++;
            }
        }

        address[] memory authorizedDoctors = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < doctorAddresses.length; i++) {
            if (patients[msg.sender].authorizedDoctors[doctorAddresses[i]]) {
                authorizedDoctors[index] = doctorAddresses[i];
                index++;
            }
        }

        return authorizedDoctors;
    }

    function viewPatientEHR(
        address patient
    ) external view onlyActiveContract returns (EHR[] memory) {
        require(
            doctors[msg.sender].metamaskAddress != address(0),
            "Doctor not found"
        );
        require(
            patients[patient].authorizedDoctors[msg.sender],
            "Access not granted"
        );
        return patients[patient].ehrs[msg.sender];
    }

    function storeUserProfileIPFSHash(
        string memory _hash
    ) public onlyActiveContract {
        userIPFSHashes[msg.sender] = _hash;
        emit UserProfileLinked(msg.sender, _hash);
    }

    function storePatientEHRIPFSHash(
        string memory _hash
    ) public onlyActiveContract {
        patientEHRIPFSHashes[msg.sender] = _hash;
    }

    function destroyContract() public onlyActiveContract {
        require(msg.sender == owner, "Only the owner can destroy the contract");
        isContractActive = false; // Mark the contract as no longer active
        // selfdestruct(payable(owner));
    }

    function getDoctorAddresses()
        public
        view
        onlyActiveContract
        returns (address[] memory)
    {
        return doctorAddresses;
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
