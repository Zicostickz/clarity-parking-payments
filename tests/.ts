import {
    Clarinet,
    Tx,
    Chain,
    Account,
    types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test parking flow - park, extend, and end parking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            // Test parking for 2 hours
            Tx.contractCall('parking-system', 'park', [
                types.uint(2)
            ], user1.address),
            
            // Test checking parking info
            Tx.contractCall('parking-system', 'get-parking-info', [
                types.principal(user1.address)
            ], user1.address),
            
            // Test extending parking by 1 hour
            Tx.contractCall('parking-system', 'extend-parking', [
                types.uint(1)
            ], user1.address),
            
            // Test ending parking
            Tx.contractCall('parking-system', 'end-parking', [], user1.address)
        ]);

        block.receipts[0].result.expectOk();
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectOk();
        block.receipts[3].result.expectOk();
    }
});

Clarinet.test({
    name: "Test admin functions and error cases",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            // Test setting hourly rate as non-owner (should fail)
            Tx.contractCall('parking-system', 'set-hourly-rate', [
                types.uint(6000000)
            ], user1.address),
            
            // Test setting hourly rate as owner (should succeed)
            Tx.contractCall('parking-system', 'set-hourly-rate', [
                types.uint(6000000)
            ], deployer.address),
            
            // Test parking with invalid duration
            Tx.contractCall('parking-system', 'park', [
                types.uint(0)
            ], user1.address)
        ]);

        block.receipts[0].result.expectErr(types.uint(100)); // err-owner-only
        block.receipts[1].result.expectOk();
        block.receipts[2].result.expectErr(types.uint(102)); // err-invalid-duration
    }
});
