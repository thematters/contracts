//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./IHarbergerMarket.sol";
import "./IDividendDAO.sol";

/**
 * @dev Pixel land where uses can tokenize pixels, trade tokens, and color pixels, inherits from `IHarbergerMarket` and `IDividendDAO`.
 */
interface ISpaceDAO is IHarbergerMarket, IDividendDAO {

}
