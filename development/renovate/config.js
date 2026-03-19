module.exports = {
  platform: 'gitlab',
  endpoint: 'https://gitlab.lab.kemo.network/api/v4',
  gitAuthor: 'Renovate Bot <renovate@lab.kemo.network>',
  autodiscover: true,
  autodiscoverFilter: ['*/*'],
  onboarding: true,
  hostRules: [
    {
      matchHost: 'gitlab.lab.kemo.network',
      insecureRegistry: false,
    },
  ],
};
