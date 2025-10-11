# Project Description and Overview

## App Description

We are designing software to be used inside Marriott Bonvoy hotels via a kiosk. The user uses the NFC chip inside their Apple phone to sign into the kiosk via the Marriott Bonvoy app.

### User Information Flow
The user's information is passed along during authentication:
- Login credentials (not used for analysis)
- Preferences (used in analysis)

### Home Screen
Once successfully authenticated and logged into the kiosk, the landing page is a home screen consisting of a full screen map with a right-bound sidebar. There may be a pop-up modal for some users prior to landing on the homepage asking about possible additions/orders to room service based on past stays and preferences data.

**Pop-up modal example:**
```
Would you like to add?
x
y
close
```

### Sidebar Categories
The sidebar contains four buttons (likely icons to reduce size prior to selection and expansion of the sidebar) for categories:
- Dining
- Attractions
- Shopping
- Night Life

### Category Selection Flow
Once a category is selected, the sidebar expands and displays a list of nearby options which have been curated for the user's preference data via the Exa RAG customization capabilities.

**Example flow:**
Selects "Night Life" → Selects TOTS

The sidebar displays:
- Company name
- Hours of operation
- LLM description curated to the user's preference (all via Exa)

### Exa Integration Details
It is important to note that Exa is passed two pieces of data:
1. The user's preferences for intelligent recommendations
2. The location which is hard coded (in a production process would be obtained via the Marriott Bonvoy kiosk sign-up process)

These two bits of information are what's used to obtain the search results for the recommendations. Perhaps even a similarity score based on past experiences could be added, allowing users to like and dislike suggestions on the frontend as well.

### Map Interaction
Upon selection, the tag for the location appears on the map showing:
- Location
- Distance from the kiosk
- Expected Uber ride time/walk time (useful for busy locations)

## Task Segmentation

**Aryan:** Swift UI components, general iOS infrastructure

**Ben:** Dining Exa agent, Mock UI

**Big Sanj:** Attractions Exa agent, ensuring rubric compliance, keeping track of what needs to be done for submission (having a perfect score via the rubric is important because multiple teams may receive this and to be a contender for top 3 we must abide strictly by the rubric)

**Shreel:** MongoDB and mock data generation to be pulled via each Exa agent and for user management, Shopping Exa agent

**Nando:** Cybersecurity compliance, keep track of all points of transit for sensitive data and document the compliance measures implemented for sensitive data and user management, Night Life Exa Agent

## Development Guidelines

Push your code and notify the team before merging.

### Git Workflow

#### Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd <repository-name>
```

#### Creating a New Branch
```bash
# Create and switch to a new branch
git checkout -b your-branch-name

# Example: git checkout -b feature/dining-agent
```

#### Making Changes
```bash
# Check status of your changes
git status

# Add specific files
git add filename.ext

# Or add all changes
git add .

# Commit your changes
git commit -m "Your commit message describing the changes"
```

#### Pushing Your Branch
```bash
# Push your branch to remote
git push origin your-branch-name

# If it's your first push on this branch
git push -u origin your-branch-name
```

#### Updating Your Branch
```bash
# Fetch latest changes from remote
git fetch origin

# Pull latest changes from main
git checkout main
git pull origin main

# Switch back to your branch
git checkout your-branch-name

# Merge main into your branch
git merge main
```

#### Before Merging to Main
1. Make sure your branch is up to date with main
2. Test your changes locally
3. Notify the team in the group chat
4. Create a pull request (if using GitHub/GitLab)
5. Wait for review/approval before merging

#### Common Commands
```bash
# View all branches
git branch -a

# Switch between branches
git checkout branch-name

# Delete a local branch
git branch -d branch-name

# View commit history
git log --oneline

# Discard changes in a file
git checkout -- filename.ext

# Undo last commit (keeps changes)
git reset --soft HEAD~1
```

# Project Description and Overview

## App Description

We are designing software to be used inside Marriott Bonvoy hotels via a kiosk. The user uses the NFC chip inside their Apple phone to sign into the kiosk via the Marriott Bonvoy app.

### User Information Flow
The user's information is passed along during authentication:
- Login credentials (not used for analysis)
- Preferences (used in analysis)

### Home Screen
Once successfully authenticated and logged into the kiosk, the landing page is a home screen consisting of a full screen map with a right-bound sidebar. There may be a pop-up modal for some users prior to landing on the homepage asking about possible additions/orders to room service based on past stays and preferences data.

**Pop-up modal example:**
```
Would you like to add?
x
y
close
```

### Sidebar Categories
The sidebar contains four buttons (likely icons to reduce size prior to selection and expansion of the sidebar) for categories:
- Dining
- Attractions
- Shopping
- Night Life

### Category Selection Flow
Once a category is selected, the sidebar expands and displays a list of nearby options which have been curated for the user's preference data via the Exa RAG customization capabilities.

**Example flow:**
Selects "Night Life" → Selects TOTS

The sidebar displays:
- Company name
- Hours of operation
- LLM description curated to the user's preference (all via Exa)

### Exa Integration Details
It is important to note that Exa is passed two pieces of data:
1. The user's preferences for intelligent recommendations
2. The location which is hard coded (in a production process would be obtained via the Marriott Bonvoy kiosk sign-up process)

These two bits of information are what's used to obtain the search results for the recommendations. Perhaps even a similarity score based on past experiences could be added, allowing users to like and dislike suggestions on the frontend as well.

### Map Interaction
Upon selection, the tag for the location appears on the map showing:
- Location
- Distance from the kiosk
- Expected Uber ride time/walk time (useful for busy locations)

## Task Segmentation

**Aryan:** Swift UI components, general iOS infrastructure

**Ben:** Dining Exa agent, Mock UI

**Big Sanj:** Attractions Exa agent, ensuring rubric compliance, keeping track of what needs to be done for submission (having a perfect score via the rubric is important because multiple teams may receive this and to be a contender for top 3 we must abide strictly by the rubric)

**Shreel:** MongoDB and mock data generation to be pulled via each Exa agent and for user management, Shopping Exa agent

**Nando:** Cybersecurity compliance, keep track of all points of transit for sensitive data and document the compliance measures implemented for sensitive data and user management, Night Life Exa Agent

## Development Guidelines

Push your code and notify the team before merging.

### Git Workflow

#### Initial Setup
```bash
# Clone the repository
git clone <repository-url>
cd <repository-name>
```

#### Creating a New Branch
```bash
# Create and switch to a new branch
git checkout -b your-branch-name

# Example: git checkout -b feature/dining-agent
```

#### Making Changes
```bash
# Check status of your changes
git status

# Add specific files
git add filename.ext

# Or add all changes
git add .

# Commit your changes
git commit -m "Your commit message describing the changes"
```

#### Pushing Your Branch
```bash
# Push your branch to remote
git push origin your-branch-name

# If it's your first push on this branch
git push -u origin your-branch-name
```

#### Updating Your Branch
```bash
# Fetch latest changes from remote
git fetch origin

# Pull latest changes from main
git checkout main
git pull origin main

# Switch back to your branch
git checkout your-branch-name

# Merge main into your branch
git merge main
```

#### Before Merging to Main
1. Make sure your branch is up to date with main
2. Test your changes locally
3. Notify the team in the group chat
4. Create a pull request (if using GitHub/GitLab)
5. Wait for review/approval before merging

#### Common Commands
```bash
# View all branches
git branch -a

# Switch between branches
git checkout branch-name

# Delete a local branch
git branch -d branch-name

# View commit history
git log --oneline

# Discard changes in a file
git checkout -- filename.ext

# Undo last commit (keeps changes)
git reset --soft HEAD~1
```