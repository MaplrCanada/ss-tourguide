
// Variables
let activeTourType = null;
let selectedQuizAnswer = null;

// DOM Elements
const mainMenu = document.getElementById('main-menu');
const tourDetails = document.getElementById('tour-details');
const tourHUD = document.getElementById('tour-hud');
const landmarkInfo = document.getElementById('landmark-info');
const knowledgeCheck = document.getElementById('knowledge-check');
const tourResults = document.getElementById('tour-results');
const speechBubble = document.getElementById('speech-bubble');

// Initialize UI
document.addEventListener('DOMContentLoaded', function() {
    // Hide all containers except main menu by default
    hideAllContainers();
});

// Hide all containers
function hideAllContainers() {
    mainMenu.style.display = 'none';
    tourDetails.style.display = 'none';
    tourHUD.style.display = 'none';
    landmarkInfo.style.display = 'none';
    knowledgeCheck.style.display = 'none';
    tourResults.style.display = 'none';
    speechBubble.style.display = 'none';
}

// Show Container with animation
function showContainer(container) {
    hideAllContainers();
    container.style.display = 'block';
    container.classList.add('fadeIn');
    setTimeout(() => {
        container.classList.remove('fadeIn');
    }, 300);
}

// Event Listeners
document.getElementById('close-menu').addEventListener('click', function() {
    hideAllContainers();
    sendData('closeUI', {});
});

document.getElementById('back-to-menu').addEventListener('click', function() {
    showContainer(mainMenu);
});

document.getElementById('start-tour').addEventListener('click', function() {
    if (activeTourType) {
        sendData('startTour', { tourType: activeTourType });
        showContainer(tourHUD);
    }
});

document.getElementById('end-active-tour').addEventListener('click', function() {
    if (confirm('Are you sure you want to end the tour early? You will not receive payment.')) {
        sendData('endTour', {});
        showContainer(mainMenu);
    }
});

document.getElementById('continue-tour').addEventListener('click', function() {
    landmarkInfo.style.display = 'none';
});

document.getElementById('finish-results').addEventListener('click', function() {
    showContainer(mainMenu);
});

// Show speech bubble
function showSpeech(text, duration = 5000) {
    const speechText = document.getElementById('speech-text');
    speechText.textContent = text;
    
    speechBubble.style.display = 'block';
    speechBubble.classList.add('pop');
    
    setTimeout(() => {
        speechBubble.style.display = 'none';
        speechBubble.classList.remove('pop');
    }, duration);
}

// Generate stars for ratings
function generateStars(container, rating) {
    container.innerHTML = '';
    
    for (let i = 1; i <= 5; i++) {
        const star = document.createElement('span');
        star.className = 'star';
        star.innerHTML = i <= rating ? '<i class="fas fa-star"></i>' : '<i class="far fa-star"></i>';
        container.appendChild(star);
    }
}

// Create tour card
function createTourCard(tourType, tourData) {
    const card = document.createElement('div');
    card.className = 'tour-card';
    card.dataset.tourType = tourType;
    
    const imageBg = tourData.image ? 
        `url('images/${tourData.image}')` : 
        `linear-gradient(to right, #2a4365, #4a5568)`;
    
    card.innerHTML = `
        <div class="tour-card-img" style="background-image: ${imageBg}"></div>
        <div class="tour-card-content">
            <h3>${tourData.name}</h3>
            <p>${tourData.description}</p>
            <div class="tour-card-details">
                <span><i class="fas fa-dollar-sign"></i> $${tourData.price}</span>
                <span><i class="fas fa-clock"></i> ${tourData.duration} mins</span>
                <span><i class="fas fa-map-pin"></i> ${tourData.tourPoints.length} stops</span>
            </div>
        </div>
    `;
    
    card.addEventListener('click', function() {
        showTourDetails(tourType, tourData);
    });
    
    return card;
}

// Populate tour details page
function showTourDetails(tourType, tourData) {
    activeTourType = tourType;
    
    document.getElementById('tour-name').textContent = tourData.name;
    document.getElementById('tour-description').textContent = tourData.description;
    document.getElementById('tour-price').textContent = '$' + tourData.price;
    document.getElementById('tour-duration').textContent = tourData.duration + ' minutes';
    document.getElementById('tour-landmarks').textContent = tourData.tourPoints.length + ' locations';
    
    // Populate landmarks list
    const landmarksList = document.getElementById('landmarks-list');
    landmarksList.innerHTML = '';
    
    tourData.tourPoints.forEach((point, index) => {
        const item = document.createElement('div');
        item.className = 'landmark-item';
        item.innerHTML = `
            <div class="landmark-number">${index + 1}</div>
            <h4>${point.name}</h4>
        `;
        landmarksList.appendChild(item);
    });
    
    showContainer(tourDetails);
}

// Create quiz options
function createQuizOptions(options) {
    const optionsContainer = document.getElementById('quiz-options');
    optionsContainer.innerHTML = '';
    selectedQuizAnswer = null;
    
    options.forEach((option, index) => {
        const button = document.createElement('button');
        button.className = 'option-btn';
        button.textContent = option;
        button.dataset.answerIndex = index + 1;
        
        button.addEventListener('click', function() {
            // Remove selected class from all options
            document.querySelectorAll('.option-btn').forEach(btn => {
                btn.classList.remove('selected');
            });
            
            // Add selected class to this option
            this.classList.add('selected');
            
            // Store selected answer
            selectedQuizAnswer = this.dataset.answerIndex;
            
            // Submit answer after a short delay
            setTimeout(() => {
                sendData('knowledgeCheckAnswer', { answer: selectedQuizAnswer });
                knowledgeCheck.style.display = 'none';
            }, 1000);
        });
        
        optionsContainer.appendChild(button);
    });
}

// Send data to client
function sendData(event, data) {
    fetch(`https://${GetParentResourceName()}/${event}`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(data)
    });
}

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch (data.type) {
        case 'OPEN_MENU':
            const toursContainer = document.getElementById('tours-container');
            toursContainer.innerHTML = '';
            
            for (const [tourType, tourData] of Object.entries(data.tours)) {
                const card = createTourCard(tourType, tourData);
                toursContainer.appendChild(card);
            }
            
            showContainer(mainMenu);
            break;
            
        case 'OPEN_SPECIFIC_TOUR':
            showTourDetails(data.tourType, data.tour);
            break;
            
        case 'TOUR_START':
            document.getElementById('active-tour-name').textContent = data.tourName;
            document.getElementById('next-destination').textContent = data.destination;
            showContainer(tourHUD);
            break;
            
        case 'UPDATE_DESTINATION':
            document.getElementById('next-destination').textContent = data.destination;
            break;
            
        case 'SHOW_LANDMARK_INFO':
            document.getElementById('landmark-name').textContent = data.name;
            document.getElementById('landmark-description').textContent = data.description;
            
            const factsList = document.getElementById('landmark-facts');
            factsList.innerHTML = '';
            
            data.facts.forEach(fact => {
                const li = document.createElement('li');
                li.textContent = fact;
                factsList.appendChild(li);
            });
            
            showContainer(landmarkInfo);
            break;
            
        case 'SHOW_KNOWLEDGE_CHECK':
            document.getElementById('quiz-question').textContent = data.question;
            createQuizOptions(data.options);
            showContainer(knowledgeCheck);
            break;
            
        case 'SHOW_TOUR_RESULTS':
            // Generate stars for ratings
            generateStars(document.getElementById('knowledge-rating'), data.ratings.knowledge);
            generateStars(document.getElementById('safety-rating'), data.ratings.safety);
            generateStars(document.getElementById('entertainment-rating'), data.ratings.entertainment);
            generateStars(document.getElementById('timeliness-rating'), data.ratings.timeliness);
            generateStars(document.getElementById('overall-rating'), data.ratings.overall);
            
            // Set payment info
            document.getElementById('base-pay').textContent = '$' + data.payment.base;
            document.getElementById('tip-amount').textContent = '$' + data.payment.tip;
            document.getElementById('total-pay').textContent = '$' + data.payment.total;
            
            showContainer(tourResults);
            break;
            
        case 'TOURIST_SPEECH':
            showSpeech(data.text);
            break;
    }
});