// Game State
const gameState = {
    credits: 10000,
    fuel: 100,
    maxFuel: 100,
    cargoCapacity: 50,
    cargo: {},
    currentLocation: 'terra',
    ship: {
        name: 'Stellar Hauler',
        speed: 1,
        fuelEfficiency: 1
    }
};

// Planet Data
const planets = {
    terra: {
        name: 'Terra Prime',
        description: 'Agricultural world known for its fertile lands and food production.',
        goods: {
            food: { basePrice: 10, supply: 'high', demand: 'low' },
            minerals: { basePrice: 50, supply: 'low', demand: 'high' },
            passengers: { basePrice: 25, supply: 'medium', demand: 'medium' }
        },
        position: { top: '50px', left: '80px' }
    },
    minerva: {
        name: 'Minerva Station',
        description: 'Industrial mining colony rich in rare minerals and metals.',
        goods: {
            food: { basePrice: 20, supply: 'low', demand: 'high' },
            minerals: { basePrice: 30, supply: 'high', demand: 'low' },
            passengers: { basePrice: 15, supply: 'low', demand: 'medium' }
        },
        position: { top: '200px', right: '80px' }
    },
    luxuria: {
        name: 'Luxuria Resort',
        description: 'Luxury tourist destination attracting wealthy travelers from across the galaxy.',
        goods: {
            food: { basePrice: 30, supply: 'medium', demand: 'high' },
            minerals: { basePrice: 40, supply: 'medium', demand: 'medium' },
            passengers: { basePrice: 50, supply: 'high', demand: 'low' }
        },
        position: { bottom: '50px', left: '50%', transform: 'translateX(-50%)' }
    }
};

// Travel distances (fuel cost)
const travelDistances = {
    terra: { minerva: 15, luxuria: 12 },
    minerva: { terra: 15, luxuria: 18 },
    luxuria: { terra: 12, minerva: 18 }
};

// Initialize game
function initGame() {
    updateUI();
    updateLocation();
    updateMarket();
    updateTravelOptions();
    positionShip();
}

// Update UI elements
function updateUI() {
    document.getElementById('credits').textContent = gameState.credits;
    document.getElementById('fuel').textContent = gameState.fuel;
    document.getElementById('cargo-used').textContent = getTotalCargo();
    document.getElementById('cargo-capacity').textContent = gameState.cargoCapacity;
}

// Get total cargo count
function getTotalCargo() {
    return Object.values(gameState.cargo).reduce((sum, amount) => sum + amount, 0);
}

// Update current location display
function updateLocation() {
    const planet = planets[gameState.currentLocation];
    document.getElementById('current-location').textContent = planet.name;
    document.getElementById('location-details').innerHTML = `<p>${planet.description}</p>`;
}

// Calculate dynamic price based on supply/demand
function calculatePrice(basePrice, supply, demand, isSellingToPlayer = true) {
    let multiplier = 1;
    
    if (isSellingToPlayer) {
        // Player buying - higher demand = higher price, higher supply = lower price
        if (supply === 'high') multiplier *= 0.8;
        if (supply === 'low') multiplier *= 1.3;
        if (demand === 'high') multiplier *= 1.2;
        if (demand === 'low') multiplier *= 0.9;
    } else {
        // Player selling - higher demand = higher price for player
        if (demand === 'high') multiplier *= 1.4;
        if (demand === 'low') multiplier *= 0.7;
        if (supply === 'high') multiplier *= 0.8;
        if (supply === 'low') multiplier *= 1.1;
    }
    
    return Math.round(basePrice * multiplier);
}

// Update market display
function updateMarket() {
    const planet = planets[gameState.currentLocation];
    const marketContainer = document.getElementById('market-goods');
    marketContainer.innerHTML = '';
    
    Object.entries(planet.goods).forEach(([goodType, goodData]) => {
        const buyPrice = calculatePrice(goodData.basePrice, goodData.supply, goodData.demand, true);
        const sellPrice = calculatePrice(goodData.basePrice, goodData.supply, goodData.demand, false);
        const playerHas = gameState.cargo[goodType] || 0;
        
        const marketItem = document.createElement('div');
        marketItem.className = 'market-item';
        marketItem.innerHTML = `
            <div>
                <strong>${goodType.charAt(0).toUpperCase() + goodType.slice(1)}</strong><br>
                <small>Buy: $${buyPrice} | Sell: $${sellPrice}</small><br>
                <small>You have: ${playerHas}</small>
            </div>
            <div>
                <button onclick="buyGood('${goodType}', ${buyPrice})" 
                        ${gameState.credits < buyPrice || getTotalCargo() >= gameState.cargoCapacity ? 'disabled' : ''}>
                    Buy
                </button>
                <button onclick="sellGood('${goodType}', ${sellPrice})" 
                        ${playerHas <= 0 ? 'disabled' : ''}>
                    Sell
                </button>
            </div>
        `;
        marketContainer.appendChild(marketItem);
    });
}

// Buy goods
function buyGood(goodType, price) {
    if (gameState.credits >= price && getTotalCargo() < gameState.cargoCapacity) {
        gameState.credits -= price;
        gameState.cargo[goodType] = (gameState.cargo[goodType] || 0) + 1;
        updateUI();
        updateMarket();
    }
}

// Sell goods
function sellGood(goodType, price) {
    if (gameState.cargo[goodType] > 0) {
        gameState.credits += price;
        gameState.cargo[goodType]--;
        if (gameState.cargo[goodType] === 0) {
            delete gameState.cargo[goodType];
        }
        updateUI();
        updateMarket();
    }
}

// Update travel options
function updateTravelOptions() {
    const travelContainer = document.getElementById('travel-options');
    travelContainer.innerHTML = '';
    
    Object.entries(planets).forEach(([planetId, planet]) => {
        if (planetId !== gameState.currentLocation) {
            const fuelCost = travelDistances[gameState.currentLocation][planetId];
            const travelOption = document.createElement('div');
            travelOption.className = 'travel-option';
            travelOption.innerHTML = `
                <div>
                    <strong>${planet.name}</strong><br>
                    <small>Fuel cost: ${fuelCost}</small>
                </div>
                <button onclick="travelTo('${planetId}', ${fuelCost})" 
                        ${gameState.fuel < fuelCost ? 'disabled' : ''}>
                    Travel
                </button>
            `;
            travelContainer.appendChild(travelOption);
        }
    });
    
    // Add refuel option
    if (gameState.fuel < gameState.maxFuel) {
        const refuelCost = (gameState.maxFuel - gameState.fuel) * 2;
        const refuelOption = document.createElement('div');
        refuelOption.className = 'travel-option';
        refuelOption.innerHTML = `
            <div>
                <strong>Refuel</strong><br>
                <small>Cost: $${refuelCost}</small>
            </div>
            <button onclick="refuel(${refuelCost})" 
                    ${gameState.credits < refuelCost ? 'disabled' : ''}>
                Refuel
            </button>
        `;
        travelContainer.appendChild(refuelOption);
    }
}

// Travel to planet
function travelTo(planetId, fuelCost) {
    if (gameState.fuel >= fuelCost) {
        gameState.fuel -= fuelCost;
        gameState.currentLocation = planetId;
        
        // Animate ship movement
        positionShip();
        
        // Update displays after animation
        setTimeout(() => {
            updateLocation();
            updateMarket();
            updateTravelOptions();
            updateUI();
        }, 1000);
    }
}

// Refuel ship
function refuel(cost) {
    if (gameState.credits >= cost) {
        gameState.credits -= cost;
        gameState.fuel = gameState.maxFuel;
        updateUI();
        updateTravelOptions();
    }
}

// Position ship on map
function positionShip() {
    const ship = document.getElementById('player-ship');
    const planet = planets[gameState.currentLocation];
    
    // Apply position styles
    Object.entries(planet.position).forEach(([property, value]) => {
        ship.style[property] = value;
    });
    
    // Clear other position properties
    const allPositionProps = ['top', 'bottom', 'left', 'right', 'transform'];
    allPositionProps.forEach(prop => {
        if (!planet.position[prop]) {
            ship.style[prop] = '';
        }
    });
}

// Add click handlers for planets
document.addEventListener('DOMContentLoaded', () => {
    Object.keys(planets).forEach(planetId => {
        const planetElement = document.getElementById(`planet-${planetId}`);
        planetElement.addEventListener('click', () => {
            if (planetId !== gameState.currentLocation) {
                const fuelCost = travelDistances[gameState.currentLocation][planetId];
                if (gameState.fuel >= fuelCost) {
                    travelTo(planetId, fuelCost);
                }
            }
        });
    });
    
    initGame();
});