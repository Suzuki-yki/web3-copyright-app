<script setup>
import { ref } from "vue";
import { ethers } from "ethers";

  const account = ref(null);
  const artName = ref('');
  const fileHash = ref('');
  const loading = ref(false);
  const record = ref(null);

// --- CONFIGURATION ---
// ⚠️ IMPORTANT: Replace these with your actual deployment data

  const CONTRACT_ADDRESS = "Your-Contract-Address-Here"; // Replace with your deployed contract address
  const CONTRACT_ABI =[
    "function uploadWork(bytes32 _hash, string memory _artName) public payable",
    "function Data(bytes32 _hash) public view returns (address author, uint256 timestamp, string memory artName)"
  ]; // Replace with your contract's ABI

  const connectWallet = async () => {
    if (typeof window.ethereum !== "undefined") {
      try {
        const accounts = await window.ethereum.request({
          method: "eth_requestAccounts",
        });
        account.value = accounts[0];
        console.log("Connected account:", account.value);
      } catch (error) {
        console.error("Error connecting to MetaMask:", error);
      }
    } else {
      alert("MetaMask is not installed. Please install it to use this app.");
    }
  };

  const handleFile = async (e) => {
    const file = e.target.files[0];
    if(!file) return;
    const arrayBuffer = await file.arrayBuffer();
    const hashBuffer = await crypto.subtle.digest("SHA-256", arrayBuffer);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    fileHash.value = '0x' + hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
  }

  const submitToChain = async () => {
    if (!fileHash.value || !artName.value) return alert("Please select a file and enter artwork name.");
    loading.value = true;
    
    try {
      const provider = new ethers.providers.Web3Provider(window.ethereum);
      const signer = provider.getSigner();
      const contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
      
      const tx = await contract.uploadWork(fileHash.value, artName.value, { value: ethers.utils.parseEther("0.01") });
      
      await tx.wait();
      const data = await contract.Data(fileHash.value);
      record.value = {
        author: data.author,
        time: new Date(data.timestamp.toNumber() * 1000).toLocaleString(),
        artName: data.artName
      };
      alert("Copyright registered successfully!");
    } catch (error) {
      alert("Error submitting to chain: " + error.message);
    } finally {
      loading.value = false;
    }
  }

</script>

<template>
  <div class="container">
    <div class="glass-card">
      <h1 class="title">Web3 Copyright <span>Hub</span></h1>
      <p class="subtitle">Securely register your creative works on the blockchain</p>
      
      <div class="section">
        <button v-if="!account" @click="connectWallet" class="btn btn-primary">
          Connect MetaMask Wallet
        </button>
        <div v-else class="account-tag"><span class="dot"></span>
          {{ account.substring(0, 6) }}...{{ account.substring(38) }}
        </div>
      </div>

      <div v-if="account" class="section fade-in"> 
        <div class="input-group">
          <label>Artwork Name</label>
          <input v-model="artName" placeholder="Enter Artwork Name" />
        </div>

        <div class="input-group">
          <label>Upload Your File</label>
          <div class="file-input-wrapper">
            <input type="file" @change="handleFile" id="file-upload" class="hidden-input" />
            <label for="file-upload" class="file-label">
              <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" 
              stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="icon">
              <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/>
              <polyline points="17 8 12 3 7 8"/>
              <line x1="12" y1="3" x2="12" y2="15"/>
              </svg>
              {{ fileHash ? 'File Hashed ' : 'Choose File' }}
            </label>
          </div>
        </div>

        <button @click="submitToChain" :disabled="loading" class="btn btn-action" >
          <span v-if="loading" class="loader"></span>
          {{ loading ? 'Processing...' : 'Register & Pay 0.01 ETH' }}
        </button>
      </div>

      <div v-if="record" class="result-card fade-in">
        <h3>Registration Certificate</h3> 
        <div class="result-item">
          <span>Author:</span>
          <p>{{ record.author }}</p>
        </div>
        <div class="result-item">
          <span>Timestamp:</span>
          <p>{{ record.time }}</p>
        </div>
        <div class="result-item">
          <span>Work ID:</span>
          <p>{{ fileHash.substring(0, 20) }}...</p>
        </div>
      </div>
    </div>
  </div>

</template>

<style scoped>

.container {
  min-height: 100vh;
  background: radial-gradient(circle at top right, #1e3a8a, #0f172a);
  display: flex;
  justify-content: center;
  align-items: center;
  font-family: 'Inter', system-ui, sans-serif;
  color: white;
}

.glass-card {
  background: rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  padding: 40px;
  width: 100%;
  max-width: 450px;
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
}

.title {
  font-size: 2rem;
  font-weight: 800;
  margin-bottom: 8px;
  text-align: center;
}

.title span {
  color: #3b82f6;
}

.subtitle {
  color: #94a3b8;
  text-align: center;
  font-size: 0.9rem;
  margin-bottom: 30px;
}

.btn {
  width: 100%;
  padding: 14px;
  border-radius: 12px;
  border: none;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
  transform: translateY(-2px);
}

.btn-action {
  background: linear-gradient(135deg, #3b82f6 0%, #1d4ed8 100%);
  color: white;
  margin-top: 20px;
}

.btn-action:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}


.input-group {
  margin-bottom: 20px;
}

.input-group label {
  display: block;
  font-size: 0.8rem;
  color: #94a3b8;
  margin-bottom: 8px;
}

input {
  width: 100%;
  background: rgba(0, 0, 0, 0.2);
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 12px;
  border-radius: 8px;
  color: white;
  outline: none;
}

input:focus {
  border-color: #3b82f6;
}

.hidden-input {
  width: 0.1px;
  height: 0.1px;
  opacity: 0;
  overflow: hidden;
  position: absolute;
  z-index: -1;
}

.custom-file-button {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  background: rgba(255, 255, 255, 0.05);
  border: 2px dashed rgba(59, 130, 246, 0.5); 
  color: #3b82f6;
  padding: 20px;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  font-weight: 500;
}

.custom-file-button:hover {
  background: rgba(59, 130, 246, 0.1);
  border-color: #3b82f6;
  transform: scale(1.02);
}

.icon {
  stroke: #3b82f6;
}

.result-card {
  margin-top: 30px;
  background: rgba(59, 130, 246, 0.1);
  border: 1px solid rgba(59, 130, 246, 0.2);
  padding: 20px;
  border-radius: 16px;
}

.result-item {
  margin-bottom: 12px;
}

.result-item span {
  font-size: 0.7rem;
  color: #3b82f6;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.result-item p {
  font-size: 0.85rem;
  word-break: break-all;
  margin: 4px 0;
}

.fade-in {
  animation: fadeIn 0.5s ease-out;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}

.loader {
  display: inline-block;
  width: 18px;
  height: 18px;
  border: 2px solid rgba(255,255,255,0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-right: 10px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
