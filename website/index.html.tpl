<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">

  <title>Terraform Lost Its Mind</title>

  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      min-height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;

      background:
        radial-gradient(circle at 20% 20%, #172554 0%, transparent 30%),
        radial-gradient(circle at 80% 80%, #3b0764 0%, transparent 30%),
        #05070c;

      font-family: "Courier New", monospace;
      color: #e6edf3;
      padding: 30px;
    }

    .terminal {
      width: 900px;
      max-width: 100%;

      background: rgba(13, 17, 23, 0.95);

      border: 1px solid #30363d;
      border-radius: 16px;

      overflow: hidden;

      box-shadow:
        0 0 40px rgba(88, 166, 255, 0.15),
        0 0 100px rgba(163, 113, 247, 0.08);
    }

    .terminal-header {
      display: flex;
      align-items: center;
      justify-content: space-between;

      padding: 15px 20px;

      background: #161b22;
      border-bottom: 1px solid #30363d;
    }

    .dots {
      display: flex;
      gap: 8px;
    }

    .dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
    }

    .red {
      background: #ff5f56;
    }

    .yellow {
      background: #ffbd2e;
    }

    .green {
      background: #27c93f;
    }

    .terminal-title {
      color: #8b949e;
      font-size: 13px;
    }

    .content {
      padding: 45px;
    }

    .brain {
      text-align: center;
      font-size: 70px;

      animation: pulse 2.5s infinite;
    }

    @keyframes pulse {
      0%, 100% {
        transform: scale(1);
        filter: drop-shadow(0 0 5px #a371f7);
      }

      50% {
        transform: scale(1.08);
        filter: drop-shadow(0 0 20px #a371f7);
      }
    }

    h1 {
      text-align: center;
      margin-top: 10px;

      font-size: 32px;
      letter-spacing: 3px;
    }

    .subtitle {
      text-align: center;
      margin-top: 10px;
      margin-bottom: 40px;

      color: #8b949e;
    }

    .status {
      display: inline-block;

      padding: 7px 14px;
      margin-bottom: 30px;

      border-radius: 30px;

      background: rgba(46, 160, 67, 0.15);
      color: #3fb950;

      font-size: 13px;
    }

    .grid {
      display: grid;
      grid-template-columns: repeat(2, 1fr);
      gap: 18px;
    }

    .card {
      background: #161b22;

      border: 1px solid #30363d;
      border-radius: 10px;

      padding: 20px;

      transition: 0.3s;
    }

    .card:hover {
      transform: translateY(-3px);
      border-color: #58a6ff;
    }

    .label {
      color: #8b949e;
      font-size: 12px;

      text-transform: uppercase;
      letter-spacing: 1px;

      margin-bottom: 8px;
    }

    .value {
      font-size: 20px;
      color: #f0f6fc;
      word-break: break-word;
    }

    .personality {
      color: #a371f7;
      font-weight: bold;
    }

    .message {
      margin-top: 30px;

      padding: 25px;

      background: #010409;

      border-left: 4px solid #a371f7;
      border-radius: 8px;
    }

    .message-title {
      color: #8b949e;
      margin-bottom: 15px;
      font-size: 13px;
    }

    .message-text {
      color: #d2a8ff;
      font-size: 19px;
      line-height: 1.6;
    }

    .footer {
      margin-top: 35px;

      border-top: 1px solid #21262d;
      padding-top: 20px;

      text-align: center;

      color: #484f58;
      font-size: 12px;
    }

    .cursor {
      display: inline-block;

      width: 9px;
      height: 17px;

      background: #58a6ff;

      margin-left: 5px;

      animation: blink 1s infinite;
    }

    @keyframes blink {
      0%, 50% {
        opacity: 1;
      }

      51%, 100% {
        opacity: 0;
      }
    }

    @media (max-width: 650px) {
      .grid {
        grid-template-columns: 1fr;
      }

      .content {
        padding: 25px;
      }

      h1 {
        font-size: 23px;
      }
    }
  </style>
</head>

<body>

<div class="terminal">

  <div class="terminal-header">

    <div class="dots">
      <div class="dot red"></div>
      <div class="dot yellow"></div>
      <div class="dot green"></div>
    </div>

    <div class="terminal-title">
      terraform@oci:~/mind
    </div>

  </div>


  <div class="content">

    <div class="brain">
      🧠
    </div>

    <h1>
      TERRAFORM LOST ITS MIND
    </h1>

    <div class="subtitle">
      OCI Infrastructure Personality Engine
    </div>

    <div class="status">
      ● INFRASTRUCTURE ONLINE
    </div>


    <div class="grid">

      <div class="card">
        <div class="label">
          Infrastructure
        </div>

        <div class="value">
          ${infrastructure_name}
        </div>
      </div>


      <div class="card">
        <div class="label">
          Personality
        </div>

        <div class="value personality">
          ${personality}
        </div>
      </div>


      <div class="card">
        <div class="label">
          Budget
        </div>

        <div class="value">
          &#36;${budget}
        </div>
      </div>


      <div class="card">
        <div class="label">
          Security Level
        </div>

        <div class="value">
          ${security_level} / 100
        </div>
      </div>


      <div class="card">
        <div class="label">
          Chaos Level
        </div>

        <div class="value">
          ${chaos_level} / 100
        </div>
      </div>


      <div class="card">
        <div class="label">
          Environment
        </div>

        <div class="value">
          ${environment}
        </div>
      </div>

    </div>


    <div class="message">

      <div class="message-title">
        terraform://internal-thought
      </div>

      <div class="message-text">
        > "${personality_message}"
        <span class="cursor"></span>
      </div>

    </div>


    <div class="footer">
      Managed by Terraform · Powered by Oracle Cloud Infrastructure
    </div>

  </div>

</div>

</body>
</html>