(function() {
    document.addEventListener('DOMContentLoaded', function() {
        const script = document.querySelector('script[data-username]');
        const username = script ? script.getAttribute('data-username') : null;

        if (!username) {
            console.error('GitHub username is required');
            return;
        }

        const container = document.createElement('div');
        container.innerHTML = `
        <h1>GitHub Activity</h1>
        <div id="calendar-container">
        <div id="day-labels">
        <div>Mon</div>
        <div>Wed</div>
        <div>Fri</div>
        </div>
        <div id="calendar-wrapper">
        <div id="month-labels"></div>
        <div id="calendar"></div>
        </div>
        </div>
        <div id="stats-container">
        <div class="stat-box">
        <p>Total Contributions</p>
        <span id="total-contributions"></span>
        </div>
        <div class="stat-box">
        <p>Longest Streak</p>
        <span id="longest-streak"></span>
        </div>
        <div class="stat-box">
        <p>Current Streak</p>
        <span id="current-streak"></span>
        </div>
        </div>
        `;
        document.body.appendChild(container);

        const style = document.createElement('style');
        style.textContent = `
        #calendar-container {
        display: flex;
        align-items: flex-start;
        margin-top: 20px;
        }
        #calendar-wrapper {
        display: flex;
        flex-direction: column;
        }
        #month-labels {
        display: flex;
        justify-content: space-between;
        margin-bottom: 5px;
        padding-left: 30px; /* Add padding to align with the calendar */
        }
        #calendar {
        display: flex;
        flex-wrap: wrap;
        width: 728px; /* Adjusted width for better visibility */
        }
        .week {
            display: flex;
            flex-direction: row;
        }
        .day {
            width: 10px;
            height: 10px;
            margin: 1px;
            background-color: #ebedf0;
        }
        .day.contributed-1 {
            background-color: #c6e48b;
        }
        .day.contributed-2 {
            background-color: #7bc96f;
        }
        .day.contributed-3 {
            background-color: #239a3b;
        }
        .day.contributed-4 {
            background-color: #196127;
        }
        #day-labels {
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        height: 100px; /* Adjust height to match the calendar */
        margin-right: 5px;
        margin-top: 18px; /* Align with the start of the weeks */
        padding-right: 10px;
        }
        #stats-container {
        display: flex;
        justify-content: center;
        margin-top: 20px;
        width: 728px; /* Match the width of the calendar */
        }
        .stat-box {
            border: 1px solid #ddd;
            padding: 10px;
            border-radius: 5px;
            width: 150px;
            text-align: center;
            margin: 0 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        `;
        document.head.appendChild(style);

        axios.get(`https://api.github.com/users/${username}/events/public`)
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
            const monthLabels = document.getElementById('month-labels');
            const today = new Date();
            const startDate = new Date(today.getFullYear() - 1, today.getMonth(), today.getDate());

            let weekDiv = document.createElement('div');
            weekDiv.className = 'week';
            calendar.appendChild(weekDiv);

            let currentMonth = startDate.getMonth();
            let monthLabel = document.createElement('div');
            monthLabel.textContent = startDate.toLocaleString('default', { month: 'short' });
            monthLabels.appendChild(monthLabel);

            for (let d = new Date(startDate); d <= today; d.setDate(d.getDate() + 1)) {
                const dateStr = d.toISOString().split('T')[0];
                const dayDiv = document.createElement('div');
                dayDiv.className = 'day';

                const count = contributions[dateStr] || 0;
                if (count > 0) {
                    dayDiv.classList.add(`contributed-${Math.min(count, 4)}`);
                }

                if (d.getDay() === 0 && d !== startDate) {
                    weekDiv = document.createElement('div');
                    weekDiv.className = 'week';
                    calendar.appendChild(weekDiv);
                }

                weekDiv.appendChild(dayDiv);

                if (d.getMonth() !== currentMonth) {
                    currentMonth = d.getMonth();
                    monthLabel = document.createElement('div');
                    monthLabel.textContent = d.toLocaleString('default', { month: 'short' });
                    monthLabel.style.flex = '1';
                    monthLabels.appendChild(monthLabel);
                }
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
    });
})();
