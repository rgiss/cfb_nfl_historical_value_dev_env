<script lang="ts">
  let activeTab = 'description';
</script>

<svelte:head>
  <title>Fantasy Football Player Analysis</title>
</svelte:head>

<div class="app-container">
  <header>
    <h1>Fantasy Football Player Analysis</h1>
  </header>

  <nav class="tab-nav">
    <button 
      class="tab-button" 
      class:active={activeTab === 'description'}
      on:click={() => activeTab = 'description'}
    >
      Description
    </button>
    <button 
      class="tab-button" 
      class:active={activeTab === 'trajectory'}
      on:click={() => activeTab = 'trajectory'}
    >
      Historical Career Trajectory
    </button>
    <button 
      class="tab-button" 
      class:active={activeTab === 'values'}
      on:click={() => activeTab = 'values'}
    >
      Current Player Values
    </button>
  </nav>

  <main>
    {#if activeTab === 'description'}
      <div class="description">
        <h2>About This Tool</h2>
        <p>This application provides fantasy football analysis based on historical player performance data.</p>
      </div>
    {:else if activeTab === 'trajectory'}
      <div class="trajectory-panel">
        <p>Trajectory visualization will be loaded here...</p>
      </div>
    {:else if activeTab === 'values'}
      <div class="values-panel">
        <h2>Player Values</h2>
        <p>Player table will be loaded here...</p>
      </div>
    {/if}
  </main>
</div>

<style>
  .app-container {
    min-height: 100vh;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    padding: 20px;
  }

  header {
    text-align: center;
    margin-bottom: 30px;
  }

  h1 {
    color: white;
    font-size: 2.5em;
    margin: 0;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
  }

  .tab-nav {
    display: flex;
    justify-content: center;
    gap: 10px;
    margin-bottom: 30px;
  }

  .tab-button {
    padding: 12px 24px;
    border: none;
    border-radius: 25px;
    background: rgba(255, 255, 255, 0.2);
    color: white;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.3s ease;
    backdrop-filter: blur(10px);
  }

  .tab-button:hover {
    background: rgba(255, 255, 255, 0.3);
    transform: translateY(-2px);
  }

  .tab-button.active {
    background: rgba(255, 255, 255, 0.9);
    color: #333;
  }

  main {
    max-width: 1200px;
    margin: 0 auto;
    background: rgba(255, 255, 255, 0.95);
    border-radius: 15px;
    padding: 30px;
    box-shadow: 0 10px 30px rgba(0,0,0,0.2);
    backdrop-filter: blur(10px);
  }

  .description h2 {
    color: #333;
    margin-bottom: 20px;
  }

  .description p {
    color: #666;
    line-height: 1.6;
    margin-bottom: 15px;
  }
</style>
