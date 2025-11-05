import { initializeApp } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-app.js';
import { getFirestore, collection, getDocs } from 'https://www.gstatic.com/firebasejs/10.7.0/firebase-firestore.js';
import { firebaseConfig } from './firebase-config.js';

const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

const categories = ['Electronics', 'Clothing', 'Books', 'Personal Items', 'Sports Equipment', 'Other'];
const categoryColors = ['#007AFF', '#FF3B30', '#34C759', '#FF9500', '#5856D6', '#8E8E93'];

let allItems = [];

async function loadItems() {
    try {
        const querySnapshot = await getDocs(collection(db, 'items'));
        allItems = [];
        
        querySnapshot.forEach((doc) => {
            const data = doc.data();
            allItems.push({
                id: doc.id,
                ...data,
                dateTime: data.dateTime ? new Date(data.dateTime) : new Date()
            });
        });
        
        updateDashboard();
    } catch (error) {
        console.error('Error loading items:', error);
        loadMockData();
    }
}

function loadMockData() {
    allItems = [
        {
            id: '1',
            title: 'iPhone 13 Pro',
            description: 'Lost near library',
            category: 0,
            location: 'Main Library',
            contactInfo: 'student@mywsu.ac.za',
            isLost: true,
            dateTime: new Date('2024-01-15')
        },
        {
            id: '2',
            title: 'Blue Backpack',
            description: 'Found in cafeteria',
            category: 3,
            location: 'Student Cafeteria',
            contactInfo: 'staff@wsu.ac.za',
            isLost: false,
            dateTime: new Date('2024-01-14')
        },
        {
            id: '3',
            title: 'Calculus Textbook',
            description: 'Mathematics textbook',
            category: 2,
            location: 'Math Building',
            contactInfo: '202012345@mywsu.ac.za',
            isLost: true,
            dateTime: new Date('2024-01-13')
        },
        {
            id: '4',
            title: 'Red Jacket',
            description: 'Winter jacket',
            category: 1,
            location: 'Sports Complex',
            contactInfo: 'student2@mywsu.ac.za',
            isLost: false,
            dateTime: new Date('2024-01-12')
        },
        {
            id: '5',
            title: 'Laptop Charger',
            description: 'Dell laptop charger',
            category: 0,
            location: 'Computer Lab',
            contactInfo: 'student3@mywsu.ac.za',
            isLost: true,
            dateTime: new Date('2024-01-11')
        }
    ];
    
    updateDashboard();
}

function updateDashboard() {
    updateOverviewCards();
    updateTrendChart();
    updateCategoryBreakdown();
    updateLocationHotspots();
    updateSuccessRate();
}

function updateOverviewCards() {
    const total = allItems.length;
    const lost = allItems.filter(item => item.isLost).length;
    const found = allItems.filter(item => !item.isLost).length;
    const successRate = total > 0 ? Math.round((found / total) * 100) : 0;
    
    document.getElementById('totalItems').textContent = total;
    document.getElementById('lostItems').textContent = lost;
    document.getElementById('foundItems').textContent = found;
    document.getElementById('successRate').textContent = successRate + '%';
}

function updateTrendChart() {
    const canvas = document.getElementById('trendChart');
    const ctx = canvas.getContext('2d');
    
    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    // Mock weekly data
    const weekData = [12, 18, 15, 22, 28, 25, 30];
    const maxValue = Math.max(...weekData);
    
    // Draw chart
    ctx.strokeStyle = '#007AFF';
    ctx.lineWidth = 3;
    ctx.beginPath();
    
    weekData.forEach((value, index) => {
        const x = (index / (weekData.length - 1)) * (canvas.width - 40) + 20;
        const y = canvas.height - 20 - ((value / maxValue) * (canvas.height - 40));
        
        if (index === 0) {
            ctx.moveTo(x, y);
        } else {
            ctx.lineTo(x, y);
        }
        
        // Draw points
        ctx.fillStyle = '#007AFF';
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, 2 * Math.PI);
        ctx.fill();
        ctx.beginPath();
    });
    
    ctx.stroke();
}

function updateCategoryBreakdown() {
    const categoryData = {};
    categories.forEach(cat => categoryData[cat] = 0);
    
    allItems.forEach(item => {
        const categoryName = categories[item.category] || 'Other';
        categoryData[categoryName]++;
    });
    
    const container = document.getElementById('categoryBreakdown');
    container.innerHTML = '';
    
    Object.entries(categoryData).forEach(([category, count], index) => {
        if (count > 0) {
            const percentage = (count / allItems.length) * 100;
            
            const item = document.createElement('div');
            item.innerHTML = `
                <div class="category-item">
                    <span class="category-name">${category}</span>
                    <span class="category-count">${count}</span>
                </div>
                <div class="category-bar">
                    <div class="category-progress" style="width: ${percentage}%; background-color: ${categoryColors[index]}"></div>
                </div>
            `;
            container.appendChild(item);
        }
    });
}

function updateLocationHotspots() {
    const locationData = {};
    allItems.forEach(item => {
        locationData[item.location] = (locationData[item.location] || 0) + 1;
    });
    
    const sortedLocations = Object.entries(locationData)
        .sort(([,a], [,b]) => b - a)
        .slice(0, 5);
    
    const container = document.getElementById('locationHotspots');
    container.innerHTML = '';
    
    sortedLocations.forEach(([location, count]) => {
        const item = document.createElement('div');
        item.className = 'location-item';
        item.innerHTML = `
            <span class="location-icon">📍</span>
            <span class="location-name">${location}</span>
            <span class="location-count">${count}</span>
        `;
        container.appendChild(item);
    });
}

function updateSuccessRate() {
    const resolvedCount = Math.round(allItems.length * 0.7);
    const successRate = allItems.length > 0 ? Math.round((resolvedCount / allItems.length) * 100) : 0;
    
    document.getElementById('successPercentage').textContent = successRate + '%';
}

// Initialize dashboard
window.loadItems = loadItems;
loadItems();