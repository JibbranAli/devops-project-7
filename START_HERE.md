# 👋 Start Here - Your MLOps Journey Begins!

Welcome! You're about to set up a complete machine learning deployment system. This guide will walk you through everything step by step.

## What You're Building

Imagine Netflix testing two recommendation algorithms to see which one users like better. Or Amazon trying out a new pricing model on 10% of customers. That's A/B testing, and you're about to build that for machine learning models!

**Your system will:**
- Serve predictions through a web API
- Let users interact through a nice web interface
- Run two model versions simultaneously
- Track which one performs better
- Monitor everything in real-time
- Deploy automatically when you make changes

## Before You Start

### What You Need
- A Linux server (Amazon Linux or Red Hat)
  - AWS EC2 works great (t3.medium or larger)
  - Or any Linux machine with 2GB+ RAM
- Ability to run admin commands (sudo)
- 20 minutes of your time

### What You DON'T Need
- Kubernetes knowledge
- Docker expertise
- DevOps background
- ML engineering experience

The scripts handle everything!

## The 5-Minute Quick Start

### Step 1: Get the Code
```bash
# If you have git
git clone <your-repo-url>
cd mlops-pipeline

# Or just upload/extract the files to your server
```

### Step 2: Make Scripts Executable
```bash
chmod +x *.sh
```

### Step 3: Install Everything
```bash
./install.sh
```

This takes about 5 minutes. It installs:
- Python and all libraries
- Docker and Docker Compose
- All system dependencies

**Grab a coffee!** ☕

### Step 4: Start Everything
```bash
./run_demo.sh
```

This takes about 2 minutes. It:
- Trains two machine learning models
- Builds Docker containers
- Starts all services

### Step 5: Test Everything
```bash
./test_everything.sh
```

This runs a complete system test and shows you:
- ✅ What's working
- ❌ What's broken (if anything)
- 🌐 The URLs to access your services

**IMPORTANT:** Copy those URLs! You'll need them.

## Understanding Your URLs

After running `./test_everything.sh`, you'll see something like:

```
Access Your Services:
  Streamlit UI:  http://54.123.45.67:8501
  Flask API:     http://54.123.45.67:5000
  Prometheus:    http://54.123.45.67:9090
```

**What are these?**

### 🎨 Streamlit UI (Port 8501)
This is your user-friendly web interface. Open it in your browser and you'll see:
- Sliders to input flower measurements
- A button to get predictions
- Results showing which flower type it is
- Stats on which model version was used

**Try it now!** Move the sliders and click "Get Prediction"

### 🔌 Flask API (Port 5000)
This is your REST API that other programs can call. Test it:

```bash
# Replace with your actual IP from test_everything.sh
curl -X POST http://YOUR-IP:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'
```

You'll get back a JSON response with the prediction!

### 📊 Prometheus (Port 9090)
This is your monitoring dashboard. Open it and try searching for:
- `prediction_requests_total` - How many predictions you've made
- `model_version_requests_total` - Which model is being used more

## Your First Prediction

Let's make your first prediction using the web interface:

1. **Open the Streamlit URL** in your browser
2. **Adjust the sliders:**
   - Sepal Length: 5.1 cm
   - Sepal Width: 3.5 cm
   - Petal Length: 1.4 cm
   - Petal Width: 0.2 cm
3. **Click "Get Prediction"**
4. **See the result:** It should say "Setosa" (a type of iris flower)
5. **Notice:** It tells you which model version made the prediction (v1 or v2)

**Congratulations!** You just used your ML system! 🎉

## Understanding A/B Testing

Here's what's happening behind the scenes:

```
Your Request
     ↓
   Router (flips a coin)
     ↓
   Heads? → Model v1 (50 trees)
   Tails? → Model v2 (100 trees)
     ↓
  Prediction
```

Each time you make a prediction, the system randomly picks one of the two models. This lets you compare them!

**Try this:**
1. Make 10 predictions in the web interface
2. Look at the statistics at the bottom
3. You'll see roughly 5 went to v1 and 5 to v2

That's A/B testing in action!

## What Each Component Does

### The API (Flask)
Think of this as a restaurant kitchen. It:
- Receives orders (prediction requests)
- Decides which chef (model) to use
- Serves the result
- Tracks everything

### The UI (Streamlit)
This is the restaurant's dining room. It:
- Provides a nice interface for customers
- Makes it easy to place orders
- Shows results in a friendly way

### The Models (v1 and v2)
These are your two chefs. They:
- Take the same ingredients (flower measurements)
- Use different recipes (50 vs 100 trees)
- Produce predictions

### The Monitor (Prometheus)
This is your quality control manager. It:
- Counts how many orders you've served
- Tracks how fast you're serving
- Watches for problems
- Records which chef is doing better

## Common First-Time Issues

### "Can't access the web interface"

**Check 1:** Are services running?
```bash
docker-compose ps
```
All should say "Up"

**Check 2:** Is your firewall blocking it?
On AWS, check your Security Group allows ports 5000, 8501, 9090

**Check 3:** Are you using the right IP?
Run `./test_everything.sh` again to see the correct URLs

### "Test script shows failures"

Run the verification script:
```bash
./verify_setup.sh
```

This tells you exactly what's missing.

### "Docker permission denied"

You need to add yourself to the docker group:
```bash
sudo usermod -aG docker $USER
```

Then **log out and log back in**.

## Next Steps

### Today (10 minutes)
1. ✅ Make predictions via the web UI
2. ✅ Try the API with curl
3. ✅ Check Prometheus metrics
4. ✅ Make 20 predictions and watch the A/B split

### This Week (1 hour)
1. Read the full README.md
2. Change the A/B split ratios
3. Retrain the models
4. Explore the code

### This Month (ongoing)
1. Deploy to AWS properly
2. Add your own models
3. Customize the UI
4. Set up Jenkins for CI/CD

## Learning Resources

### Start Simple
- **README.md** - Main documentation (read this next!)
- **QUICKSTART.md** - Quick command reference
- **GETTING_STARTED.md** - Detailed beginner guide

### Go Deeper
- **ARCHITECTURE.md** - How everything works
- **DIAGRAMS.md** - Visual explanations
- **FINAL_SUMMARY.md** - Complete overview

### Get Specific
- **Jenkinsfile** - See the CI/CD pipeline
- **docker-compose.yml** - See how services connect
- **app/flask_app.py** - See the API code
- **app/streamlit_app.py** - See the UI code

## Helpful Commands

```bash
# See if everything is running
docker-compose ps

# View logs
docker-compose logs -f

# Restart everything
docker-compose restart

# Stop everything
docker-compose down

# Start everything
docker-compose up -d

# Test everything
./test_everything.sh

# Check for model drift
python app/monitoring.py
```

## Getting Help

**Something not working?**

1. Run `./test_everything.sh` - shows what's broken
2. Run `./verify_setup.sh` - checks installation
3. Check logs: `docker-compose logs`
4. Read the troubleshooting section in README.md

**Want to understand more?**

1. Read README.md - comprehensive guide
2. Check ARCHITECTURE.md - deep technical dive
3. Look at DIAGRAMS.md - visual explanations
4. Explore the code - it's well commented!

## What Makes This Special

Most ML tutorials show you how to train a model and stop there. This shows you:
- How to deploy it
- How to serve it to users
- How to monitor it
- How to test improvements
- How to automate everything

**This is the real-world stuff that matters!**

## Your Achievement

By following this guide, you've:
- ✅ Deployed a complete ML system
- ✅ Set up A/B testing
- ✅ Implemented monitoring
- ✅ Created a user interface
- ✅ Built a REST API
- ✅ Containerized everything

**That's impressive!** Most people never get this far.

## The Big Picture

```
┌─────────────────────────────────────────┐
│  You just built what companies pay      │
│  ML engineers $150k+/year to create!    │
└─────────────────────────────────────────┘
```

This isn't a toy project. This is:
- How Netflix tests recommendations
- How Amazon tests pricing
- How Google tests search results
- How Spotify tests playlists

You now have that capability!

## Ready to Dive Deeper?

**Next, read:** [README.md](README.md) - The complete guide

**Or jump to:**
- [QUICKSTART.md](QUICKSTART.md) - Quick reference
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details
- [FINAL_SUMMARY.md](FINAL_SUMMARY.md) - Project overview

## One More Thing

**Bookmark these URLs** (from your test_everything.sh output):
- Your web interface
- Your API endpoint
- Your monitoring dashboard

You'll use them a lot!

---

## Quick Reference

```bash
# The three essential commands
./install.sh           # Install (once)
./run_demo.sh          # Start
./test_everything.sh   # Test

# Daily commands
docker-compose ps      # Check status
docker-compose logs -f # Watch logs
docker-compose restart # Restart

# URLs (replace YOUR-IP)
http://YOUR-IP:8501    # Web UI
http://YOUR-IP:5000    # API
http://YOUR-IP:9090    # Monitoring
```

---

**You're all set! Go make some predictions!** 🚀

Questions? Check README.md or run `./test_everything.sh` to diagnose issues.
