# PredictionMarketAI

Prediction markets specifically for AI milestones and breakthroughs, enabling the community to forecast AI developments while creating valuable market intelligence.

## Features

- **AI-Focused Markets**: Specialized categories for AI developments and milestones
- **Binary Prediction Markets**: YES/NO betting on specific AI outcomes
- **Automated Payouts**: Winners automatically claim proportional rewards
- **Authorized Resolvers**: Trusted experts resolve market outcomes
- **Real-Time Odds**: Dynamic probability calculation based on market activity
- **Category System**: Organized markets by AI development areas

## Market Categories

- AGI Breakthrough
- Compute Milestones
- Model Capabilities  
- Industry Adoption
- Regulation & Policy

## Contract Functions

### Public Functions
- `initialize()` - Set up market categories and initial resolvers
- `create-market(title, description, category, resolution-blocks)` - Create new prediction market
- `buy-shares(market-id, prediction, amount)` - Purchase YES/NO shares
- `resolve-market(market-id, outcome)` - Resolve market outcome (authorized resolvers)
- `claim-winnings(market-id)` - Claim winnings from resolved markets
- `authorize-resolver(resolver)` - Add authorized market resolver (owner only)

### Read-Only Functions
- `get-market(market-id)` - Get market details and current state
- `get-user-position(market-id, user)` - Get user's position in specific market
- `get-market-odds(market-id)` - Calculate current market probabilities
- `is-authorized-resolver(resolver)` - Check resolver authorization status
- `get-market-count()` - Get total number of markets

## Usage Flow

1. Create markets for AI milestones using `create-market()`
2. Users buy YES/NO shares with `buy-shares()` based on their predictions
3. Market odds dynamically adjust based on share distribution
4. After resolution date, authorized resolvers call `resolve-market()`
5. Winners claim proportional payouts with `claim-winnings()`

## Market Mechanics

- **Share Price**: 1 STX = 1 share
- **Payout**: Winners split the entire market pool proportionally
- **Resolution**: Markets resolve after specified block height
- **Odds**: Calculated as share distribution percentages

## Forecasting Value

These markets create valuable forecasting data by aggregating community predictions about AI developments, helping researchers and organizations better understand timeline expectations for various AI milestones.

## Testing

Run tests using Clarinet:
```bash
clarinet test