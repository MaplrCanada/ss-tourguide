const uiContainer = document.getElementById('ui-container');
const tourSelectionPanel = document.getElementById('tour-selection');
const tourDashboardPanel = document.getElementById('tour-dashboard');
const tourOptionsContainer = document.getElementById('tour-options');
const closeSelectionButton = document.getElementById('close-selection');

const tourNameEl = document.getElementById('tour-name');
const poiStatusEl = document.getElementById('poi-status');
const poiNameEl = document.getElementById('poi-name');
const poiDistanceEl = document.getElementById('poi-distance');
const avgRatingEl = document.getElementById('avg-rating');

const poiInteractionArea = document.getElementById('poi-interaction');
const poiInfoArea = document.getElementById('poi-info');
const poiInfoTextEl = document.getElementById('poi-info-text');
const quizSection = document.getElementById('quiz-section');
const quizQuestionTextEl = document.getElementById('quiz-question-text');
const quizOptionsContainer = document.getElementById('quiz-options');

const nextPoiButton = document.getElementById('btn-next-poi');
const endTourButton = document.getElementById('btn-end-tour');

// Utility to send NUI messages to Lua
async function post(event, data = {}) {
    try {
        const response = await fetch(`https://${GetParentResourceName()}/${event}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json; charset=UTF-8' },
            body: JSON.stringify(data)
        });
        return await response.json(); // Returns promise from Lua callback
    } catch (e) {
        console.error(`Error posting NUI event ${event}:`, e);
        return { ok: false, error: e.message }; // Indicate failure
    }
}

// --- Event Listeners from Lua ---
window.addEventListener('message', (event) => {
    const msg = event.data;
    const action = msg.action;
    const data = msg.data;

    // console.log(`NUI received: ${action}`, data); // Debugging

    switch (action) {
        case 'setVisible':
            setUIVisibility(data.visible);
            break;
        case 'showTourSelection':
            showTourSelection(data);
            break;
        case 'updateState':
            updateDashboard(data);
            break;
        case 'showPOIInfo':
            showPOIInfo(data);
            break;
        case 'showQuiz':
            showQuiz(data);
            break;
        case 'hideQuiz':
            hideQuiz();
            break;
        default:
            // console.log(`Unknown NUI action: ${action}`);
            break;
    }
});

// --- UI Visibility ---
function setUIVisibility(visible) {
    if (visible) {
        uiContainer.classList.remove('hidden');
        // Decide which panel to show initially (maybe none until specific data arrives)
    } else {
        uiContainer.classList.add('hidden');
        // Hide all specific panels when main container hides
        tourSelectionPanel.classList.add('hidden');
        tourDashboardPanel.classList.add('hidden');
        poiInteractionArea.classList.add('hidden'); // Ensure interaction area also hides
    }
}

// --- Tour Selection ---
function showTourSelection(toursData) {
    tourOptionsContainer.innerHTML = ''; // Clear previous options
    if (toursData && toursData.length > 0) {
        toursData.forEach(tour => {
            const div = document.createElement('div');
            div.classList.add('tour-option');
            div.dataset.tourKey = tour.key; // Store key for later use
            div.innerHTML = `${tour.label} <span>(~${tour.time} mins)</span>`;
            div.onclick = () => selectTour(tour.key);
            tourOptionsContainer.appendChild(div);
        });
        tourSelectionPanel.classList.remove('hidden');
        tourDashboardPanel.classList.add('hidden'); // Hide dashboard if visible
    } else {
        tourOptionsContainer.innerHTML = '<p>No tours available.</p>';
        tourSelectionPanel.classList.remove('hidden');
    }
     // Ensure main container is visible when selection shows
    uiContainer.classList.remove('hidden');
}

function selectTour(tourKey) {
    console.log(`Selected tour: ${tourKey}`);
    post('startSelectedTour', { tourKey: tourKey });
    // Lua callback will handle hiding selection and showing dashboard if successful
}

closeSelectionButton.addEventListener('click', () => {
    post('closeNui'); // Ask Lua to handle closing logic
});


// --- Tour Dashboard Update ---
function updateDashboard(state) {
    if (!state || !state.onTour) {
        tourDashboardPanel.classList.add('hidden');
        return;
    }

    tourSelectionPanel.classList.add('hidden'); // Ensure selection is hidden
    tourDashboardPanel.classList.remove('hidden'); // Show dashboard

    tourNameEl.textContent = state.tourName || 'Tour in Progress';
    poiStatusEl.textContent = `${state.currentPOIIndex || '?'} / ${state.totalPOIs || '?'}`;
    poiNameEl.textContent = state.poiName || '---';
    poiDistanceEl.textContent = state.distance >= 0 ? `${Math.round(state.distance)} m` : '---';
    avgRatingEl.textContent = `${Math.round((state.avgRating || 0) * 100)}%`;

    // Handle "Next POI" button visibility
    // Show only when at a POI, not returning, and no quiz active
    if (state.atPOI && !state.returning && !state.quizActive) {
        nextPoiButton.classList.remove('hidden');
    } else {
        nextPoiButton.classList.add('hidden');
    }

    // If returning, change POI name display perhaps
    if (state.returning) {
        poiNameEl.textContent = "Return to Depot";
        poiStatusEl.textContent = "Returning";
    }

    // If quiz is not active and player is not at POI, hide interaction area
    if (!state.quizActive && !state.atPOI) {
        poiInteractionArea.classList.add('hidden');
    }
     // Ensure main container is visible when dashboard shows
     uiContainer.classList.remove('hidden');
}

// --- POI Info & Quiz Display ---
function showPOIInfo(poiData) {
    if (!poiData) return;
    poiInfoTextEl.textContent = poiData.info || 'No information available.';
    poiInfoArea.classList.remove('hidden');
    poiInteractionArea.classList.remove('hidden'); // Show the parent container
    quizSection.classList.add('hidden'); // Hide quiz section when showing info
}

function showQuiz(quizData) {
    if (!quizData || !quizData.q || !quizData.options) return;
    quizQuestionTextEl.textContent = quizData.q;
    quizOptionsContainer.innerHTML = ''; // Clear previous options

    quizData.options.forEach(option => {
        const button = document.createElement('button');
        button.classList.add('quiz-option');
        button.textContent = option;
        button.onclick = () => submitAnswer(option);
        quizOptionsContainer.appendChild(button);
    });

    quizSection.classList.remove('hidden');
    poiInfoArea.classList.add('hidden'); // Hide POI info text when showing quiz
    poiInteractionArea.classList.remove('hidden'); // Show parent container
    nextPoiButton.classList.add('hidden'); // Hide "Next POI" while quiz is active
}

function hideQuiz() {
    quizSection.classList.add('hidden');
    // Decide if POI info should re-appear or if the whole interaction area should hide
    // If player is still at POI, maybe show info again?
    // For now, just hide quiz section. Lua logic controls overall visibility.
}

function submitAnswer(answer) {
    console.log(`Submitting answer: ${answer}`);
    post('submitQuizAnswer', { answer: answer });
    // Lua callback will handle hiding quiz/showing next steps
}

// --- Control Button Actions ---
nextPoiButton.addEventListener('click', () => {
    post('nextPOI');
});

endTourButton.addEventListener('click', () => {
    // Optional: Add a confirmation dialog here?
    console.log("Requesting end tour early.");
    post('endTourEarly');
});

// --- Keyboard listener (e.g., ESC to close) ---
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        // Only close if the selection panel is visible, otherwise let game handle Esc
        if (!tourSelectionPanel.classList.contains('hidden')) {
             post('closeNui');
        } else if (!tourDashboardPanel.classList.contains('hidden')) {
            // Optional: Allow Esc to close dashboard too? Could be annoying.
            // post('closeNui'); // If you want Esc to close dashboard too
        }
    }
});

// Initial state: UI hidden
setUIVisibility(false);
console.log("Tour Guide UI Initialized.");