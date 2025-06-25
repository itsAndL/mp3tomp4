import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "progressBar", "progressText", "progressContainer", "downloadSection"]
  static values = { id: Number }
  
  connect() {
    if (this.hasStatusTarget) {
      const status = this.statusTarget.textContent.trim().toLowerCase()
      if (status === 'pending' || status === 'processing') {
        this.startPolling()
      }
    }
  }
  
  disconnect() {
    this.stopPolling()
  }
  
  startPolling() {
    this.pollInterval = setInterval(() => {
      this.checkStatus()
    }, 2000) // Poll every 2 seconds
  }
  
  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
    }
  }
  
  async checkStatus() {
    try {
      const response = await fetch(`/video_conversions/${this.idValue}/status`, {
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        }
      })
      
      if (!response.ok) throw new Error('Network response was not ok')
      
      const data = await response.json()
      this.updateUI(data)
      
      if (data.status === 'completed' || data.status === 'failed') {
        this.stopPolling()
        if (data.status === 'completed' && data.download_url) {
          this.showDownloadButton(data.download_url)
        }
      }
    } catch (error) {
      console.error('Error checking status:', error)
      this.stopPolling()
    }
  }
  
  updateUI(data) {
    // Update status badge
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = data.status.charAt(0).toUpperCase() + data.status.slice(1)
      
      // Update status badge colors
      this.statusTarget.className = this.statusTarget.className.replace(
        /bg-\w+-100 text-\w+-800/g,
        this.getStatusClasses(data.status)
      )
    }
    
    // Update progress
    if (this.hasProgressBarTarget) {
      this.progressBarTarget.style.width = `${data.progress}%`
    }
    
    if (this.hasProgressTextTarget) {
      this.progressTextTarget.textContent = `${data.progress}%`
    }
    
    // Hide progress bar when completed
    if (data.status === 'completed' && this.hasProgressContainerTarget) {
      this.progressContainerTarget.classList.add('hidden')
    }
  }
  
  getStatusClasses(status) {
    const classes = {
      'pending': 'bg-yellow-100 text-yellow-800',
      'processing': 'bg-blue-100 text-blue-800',
      'completed': 'bg-green-100 text-green-800',
      'failed': 'bg-red-100 text-red-800'
    }
    return classes[status] || 'bg-gray-100 text-gray-800'
  }
  
  showDownloadButton(downloadUrl) {
    if (this.hasDownloadSectionTarget) {
      this.downloadSectionTarget.classList.remove('hidden')
      // Reload the page to get the updated download link
      window.location.reload()
    }
  }
}