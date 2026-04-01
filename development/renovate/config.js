module.exports = {
  platform: 'gitlab',
  endpoint: 'https://gitlab.lab.kemo.dev/api/v4',
  gitAuthor: 'Renovate Bot <renovate@lab.kemo.dev>',
  autodiscover: true,
  autodiscoverFilter: ['*/*'],
  onboarding: true,
  hostRules: [
    {
      matchHost: 'gitlab.lab.kemo.dev',
      insecureRegistry: false,
    },
  ],
};
