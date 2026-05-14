document.addEventListener('DOMContentLoaded', () => {
  loadSkills();
  loadProjects();
  initNavToggle();
});

async function loadSkills() {
  const grid = document.getElementById('skills-grid');
  try {
    const res   = await fetch('/api/skills');
    const data  = await res.json();
    grid.innerHTML = data.map(cat => `
      <div class="skill-card">
        <h3>${cat.category}</h3>
        <div>
          ${cat.items.map(item => `<span class="skill-tag">${item}</span>`).join('')}
        </div>
      </div>
    `).join('');
  } catch (e) {
    grid.innerHTML = '<p class="loading">Could not load skills.</p>';
  }
}

async function loadProjects() {
  const grid = document.getElementById('projects-grid');
  try {
    const res  = await fetch('/api/projects');
    const data = await res.json();
    grid.innerHTML = data.map(proj => `
      <div class="project-card">
        <h3>${proj.title}</h3>
        <p>${proj.description}</p>
        <div class="project-tags">
          ${proj.tags.map(t => `<span class="project-tag">${t}</span>`).join('')}
        </div>
        <a class="project-link" href="${proj.github}" target="_blank" rel="noopener">
          View on GitHub →
        </a>
      </div>
    `).join('');
  } catch (e) {
    grid.innerHTML = '<p class="loading">Could not load projects.</p>';
  }
}

function initNavToggle() {
  const btn   = document.getElementById('navToggle');
  const links = document.querySelector('.nav-links');
  if (!btn || !links) return;
  btn.addEventListener('click', () => {
    links.classList.toggle('open');
  });
}