(function() {
    const script = document.currentScript;
    const username = script.getAttribute('data-username');

    if (!username) {
        console.error('GitHub username is required');
        return;
    }

    const container = document.createElement('div');
    container.innerHTML = `
        <h1>GitHub Activity</h1>
        <div id="calendar"></div>
        <p>Total Contributions in the last year: <span id="total-contributions"></span></p>
        <p>Longest Streak: <span id="longest-streak"></span></p>
        <p>Current Streak: <span id="current-streak"></span></p>
    `;
    document.body.appendChild(container);

    const style = document.createElement('style');
    style.textContent = `
        #calendar {
            display: flex;
            flex-wrap: wrap;
            width: 700px;
        }
        .day {
            width: 20px;
            height: 20px;
            margin: 2px;
            background-color: #ebedf0;
        }
        .day.contributed {
            background-color: #216e39;
        }
    `;
    document.head.appendChild(style);

    axios.get(`https://api.github.com/users/${username}/events`)
        .then(response => {
            const events = response.data;
            const contributions = {};

            events.forEach(event => {
                const date = new Date(event.created_at).toISOString().split('T')[0];
                contributions[date] = (contributions[date] || 0) + 1;
            });

            displayCalendar(contributions);
            displayStats(contributions);
        })
        .catch(error => {
            console.error('Error fetching GitHub activity:', error);
        });

    function displayCalendar(contributions) {
        const calendar = document.getElementById('calendar');
        const today = new Date();
        const startDate = new Date(today.setFullYear(today.getFullYear() - 1));

        for (let d = new Date(startDate); d <= today; d.setDate(d.getDate() + 1)) {
            const dateStr = d.toISOString().split('T')[0];
            const dayDiv = document.createElement('div');
            dayDiv.className = 'day';
            if (contributions[dateStr]) {
                dayDiv.classList.add('contributed');
            }
            calendar.appendChild(dayDiv);
        }
    }

    function displayStats(contributions) {
        const dates = Object.keys(contributions);
        const totalContributions = dates.reduce((sum, date) => sum + contributions[date], 0);
        document.getElementById('total-contributions').textContent = totalContributions;

        let longestStreak = 0;
        let currentStreak = 0;
        let maxStreak = 0;
        let lastDate = null;

        dates.sort().forEach(date => {
            const diff = lastDate ? (new Date(date) - new Date(lastDate)) / (1000 * 60 * 60 * 24) : 0;
            if (diff === 1) {
                currentStreak++;
            } else {
                maxStreak = Math.max(maxStreak, currentStreak);
                currentStreak = 1;
            }
            lastDate = date;
        });

        longestStreak = Math.max(maxStreak, currentStreak);
        document.getElementById('longest-streak').textContent = longestStreak;
        document.getElementById('current-streak').textContent = currentStreak;
    }
})();
