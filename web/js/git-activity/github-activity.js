/**
 * GitHub Activity Display Script
 *
 * This script allows you to display a GitHub user's activity on your website,
 * including total contributions, longest streak, and current streak over the past year.
 * It also includes a configurable heading and link to the user's GitHub profile.
 *
 * Developed by Jonathan Wilson, https://www.jonathancw.com/
 * Github Repository is https://github.com/jcunix/public-scripts
 *
 * Configuration:
 * - data-username: (required) The GitHub username to display activity for.
 * - data-show-heading: (optional) Set to `true` to show the heading, `false` to hide it. Default is `true`.
 * - data-background-color: (optional) The background color of the display. Default is `#fff`.
 * - data-text-color: (optional) The text color. Default is `#000`.
 * - data-heading-color: (optional) The color of the heading text. Default is `#000`.
 * - data-link-color: (optional) The color of the link to the GitHub profile. Default is `#000`.
 * - data-align: (optional) The alignment of the display. Options are `left` or `center`. Default is `left`.
 * - data-display-name: (optional) A custom display name to show in the heading. If not provided, the username will be used.
 *
 * Example Usage:
 * <script src="https://cdn.jsdelivr.net/gh/jcunix/public-scripts@latest/web/js/git-activity/github-activity.js"
 *         data-username="your-github-username"
 *         data-show-heading="true"
 *         data-background-color="#f0f0f0"
 *         data-text-color="#333"
 *         data-heading-color="#ff0000"
 *         data-link-color="#0066cc"
 *         data-align="center"
 *         data-display-name="John Doe"></script>
 *
 * Dependencies:
 * - Axios (https://cdn.jsdelivr.net/npm/axios/dist/axios.min.js)
 *
 * License:
 * This project is licensed under the GNU AGPLv3
 */

(function() {
    document.addEventListener('DOMContentLoaded', function() {
        const script = document.querySelector('script[data-username]');
        const username = script ? script.getAttribute('data-username') : null;
        const showHeading = script ? script.getAttribute('data-show-heading') !== 'false' : true;
        const backgroundColor = script ? script.getAttribute('data-background-color') || '#fff' : '#fff';
        const textColor = script ? script.getAttribute('data-text-color') || '#000' : '#000';
        const headingColor = script ? script.getAttribute('data-heading-color') || '#000' : '#000';
        const linkColor = script ? script.getAttribute('data-link-color') || '#000' : '#000';
        const align = script ? script.getAttribute('data-align') || 'left' : 'left';
        const displayName = script ? script.getAttribute('data-display-name') || username : username;

        if (!username) {
            console.error('GitHub username is required');
            return;
        }

        const container = document.createElement('div');
        container.className = 'github-activity-container';
        container.innerHTML = `
        ${showHeading ? `<h1 class="github-activity-heading">${displayName} GitHub Activity</h1>` : ''}
        <table id="github-calendar-table" style="background-color: ${backgroundColor}; color: ${textColor}; margin: ${align === 'center' ? '20px auto' : '20px 0'};">
        <tr>
        <td id="github-calendar-container">
        <div id="github-day-labels">
        <div>Mon</div>
        <div>Wed</div>
        <div>Fri</div>
        </div>
        <div id="github-calendar-wrapper">
        <div id="github-month-labels"></div>
        <div id="github-calendar"></div>
        </div>
        </td>
        </tr>
        <tr>
        <td id="github-stats-container">
        <div class="github-stat-box">
        <p><strong>Total Contributions</strong></p>
        <span id="github-total-contributions"></span> Total
        <small id="github-total-date-range"></small>
        </div>
        <div class="github-stat-box">
        <p><strong>Longest Streak</strong></p>
        <span id="github-longest-streak"></span> Total
        </div>
        <div class="github-stat-box">
        <p><strong>Current Streak</strong></p>
        <span id="github-current-streak"></span> Total
        </div>
        </td>
        </tr>
        </table>
        <a id="github-link" href="https://github.com/${username}" target="_blank" style="display: block; text-align: ${align}; margin-top: 10px; color: ${linkColor};">View GitHub Profile</a>
        `;
        
        const placeholder = document.getElementById('github-activity-placeholder');
        if (placeholder) {
            placeholder.appendChild(container);
        } else {
            document.body.appendChild(container);
        }

        const style = document.createElement('style');
        style.textContent = `
        .github-activity-container .github-activity-heading {
            text-align: ${align};
            color: ${headingColor};
        }
        .github-activity-container #github-calendar-table {
            border: 1px solid #ddd;
            border-collapse: collapse;
            width: 100%;
            max-width: 750px;
            background-color: ${backgroundColor};
            color: ${textColor};
        }
        .github-activity-container #github-calendar-container {
            display: flex;
            align-items: flex-start;
            padding: 20px;
        }
        .github-activity-container #github-calendar-wrapper {
            display: flex;
            flex-direction: column;
        }
        .github-activity-container #github-month-labels {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
            padding-left: 30px;
            font-weight: bold;
        }
        .github-activity-container #github-calendar {
            display: grid;
            grid-template-columns: repeat(53, 16px); /* Ensure it spans across 53 weeks */
            grid-gap: 2px;
            width: fit-content;
        }
        .github-activity-container .week {
            display: contents;
        }
        .github-activity-container .day {
            width: 14px;
            height: 14px;
            background-color: #ebedf0;
        }
        .github-activity-container .day.contributed-1 {
            background-color: #c6e48b;
        }
        .github-activity-container .day.contributed-2 {
            background-color: #7bc96f;
        }
        .github-activity-container .day.contributed-3 {
            background-color: #239a3b;
        }
        .github-activity-container .day.contributed-4 {
            background-color: #196127;
        }
        .github-activity-container #github-day-labels {
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            height: 112px; /* Adjust height to match the calendar */
            margin-right: 5px;
            margin-top: 18px;
            padding-right: 10px;
        }
        .github-activity-container #github-day-labels div {
            height: 14px;
            line-height: 14px;
            font-weight: bold;
        }
        .github-activity-container #github-stats-container {
            display: flex;
            justify-content: space-evenly;
            padding: 10px 20px; /* Reduce padding */
        }
        .github-activity-container .github-stat-box {
            border: 1px solid #ddd;
            padding: 5px; /* Reduce padding */
            border-radius: 5px;
            width: 150px;
            text-align: center;
            margin: 0 5px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
        }
        .github-activity-container .github-stat-box p {
            margin: 5px 0; /* Reduce margin */
        }
        .github-activity-container .github-stat-box small {
            display: block;
            margin-top: 5px;
            font-size: 0.8em;
            color: ${textColor}; /* Use the same text color */
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
            const calendar = document.getElementById('github-calendar');
            const monthLabels = document.getElementById('github-month-labels');
            const today = new Date();
            const startDate = new Date(today.getFullYear() - 1, today.getMonth(), today.getDate());

            let currentMonth = startDate.getMonth();
            let monthLabel = document.createElement('div');
            monthLabel.textContent = startDate.toLocaleString('default', { month: 'short' });
            monthLabel.style.gridColumnStart = 1;
            monthLabels.appendChild(monthLabel);

            let weekCount = 0;
            let dayCount = 0;

            for (let d = new Date(startDate); d <= today; d.setDate(d.getDate() + 1)) {
                if (dayCount >= 7 * 53) break; // Limit to 7 rows and 53 columns (one year)

                if (d.getDay() === 0 && d !== startDate) {
                    weekCount++;
                }

                const dateStr = d.toISOString().split('T')[0];
                const dayDiv = document.createElement('div');
                dayDiv.className = 'day';

                const count = contributions[dateStr] || 0;
                if (count > 0) {
                    dayDiv.classList.add(`contributed-${Math.min(count, 4)}`);
                }

                calendar.appendChild(dayDiv);
                dayCount++;

                if (d.getMonth() !== currentMonth) {
                    currentMonth = d.getMonth();
                    monthLabel = document.createElement('div');
                    monthLabel.textContent = d.toLocaleString('default', { month: 'short' });
                    monthLabel.style.gridColumnStart = weekCount + 1;
                    monthLabels.appendChild(monthLabel);
                }
            }
        }

        function displayStats(contributions) {
            const dates = Object.keys(contributions);
            const totalContributions = dates.reduce((sum, date) => sum + contributions[date], 0);
            document.getElementById('github-total-contributions').textContent = totalContributions;

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
            document.getElementById('github-longest-streak').textContent = longestStreak;
            document.getElementById('github-current-streak').textContent = currentStreak;

            const startDate = new Date(dates[0]);
            const endDate = new Date(dates[dates.length - 1]);
            const startMonthYear = startDate.toLocaleString('default', { month: 'short', year: 'numeric' });
            const endMonthYear = endDate.toLocaleString('default', { month: 'short', year: 'numeric' });

            document.getElementById('github-total-date-range').textContent = `${startMonthYear} - ${endMonthYear}`;
        }
    });
})();
